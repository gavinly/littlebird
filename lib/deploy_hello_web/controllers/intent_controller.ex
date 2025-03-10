defmodule DeployHelloWeb.IntentController do
  use DeployHelloWeb, :controller
  require Logger
  alias DeployHello.IntentStore

  def index(conn, _params) do
    intents = DeployHello.IntentStore.list_intents()
    render(conn, :index, layout: false, intents: intents)
  end

  def create(conn, %{"intent" => intent_params}) do
    Logger.info("Creating new intent with params: #{inspect(intent_params)}")
    # Create a more Anoma-like intent structure
    intent = %{
      id: generate_intent_id(),
      type: "transfer",  # Could be: transfer, swap, etc.
      source: intent_params["source"],
      target: intent_params["target"],
      amount: intent_params["amount"],
      constraints: %{
        # Example constraints that could be matched
        min_amount: String.to_integer(intent_params["amount"]),
        max_delay: 100  # blocks
      },
      status: "pending",
      timestamp: DateTime.utc_now()
    }
    
    Logger.info("Storing intent: #{inspect(intent)}")
    # Store the intent
    IntentStore.store_intent(intent)
    
    # Try to match with existing intents
    case match_intents(intent) do
      {:ok, matched_intent} ->
        Logger.info("Found matching intent: #{inspect(matched_intent)}")
        # Update both intents to matched status
        matched_intent = Map.put(matched_intent, :status, "matched")
        intent = Map.put(intent, :status, "matched")
        
        # Find any circular matches that complete the chain
        existing_intents = IntentStore.list_intents()
        transfer_graph = build_transfer_graph([intent, matched_intent | existing_intents])
        case find_cycles(transfer_graph, intent.source) do
          {:ok, cycle, amount} ->
            Logger.info("Found circular match with cycle #{inspect(cycle)} for amount #{amount}")
            # Update all intents in the cycle to matched status
            Enum.zip(cycle, tl(cycle) ++ [hd(cycle)])
            |> Enum.each(fn {from, to} ->
              case Enum.find(existing_intents, fn i -> 
                i.status == "pending" && i.source == from && i.target == to 
              end) do
                nil -> nil
                circular_intent ->
                  updated_intent = Map.put(circular_intent, :status, "matched")
                  IntentStore.store_intent(updated_intent)
              end
            end)
          :no_match -> nil
        end
        
        IntentStore.store_intent(matched_intent)
        IntentStore.store_intent(intent)
        
        # In a real system, this would trigger the intent resolution
        Logger.info("Matched intents: #{intent.id} with #{matched_intent.id}")
        
        conn
        |> put_status(:ok)
        |> json(%{status: "success", message: "Intent submitted and matched!"})
        
      :no_match ->
        Logger.info("No matching intent found")
        conn
        |> put_status(:ok)
        |> json(%{status: "success", message: "Intent submitted successfully!"})
    end
  end

  def list(conn, _params) do
    intents = DeployHello.IntentStore.list_intents()
    json(conn, %{
      pending_intents: Enum.filter(intents, & &1.status == "pending"),
      matched_intents: Enum.filter(intents, & &1.status == "matched")
    })
  end

  def submit(conn, %{"intent" => intent_params}) do
    DeployHello.IntentStore.add_intent(intent_params)
    redirect(conn, to: ~p"/")
  end

  def health(conn, _params) do
    json(conn, %{status: "ok"})
  end

  # Private helper functions

  defp generate_intent_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp match_intents(new_intent) do
    existing_intents = IntentStore.list_intents()
    Logger.info("Checking for matches against existing intents: #{inspect(existing_intents)}")
    
    # First try direct matches
    case find_direct_match(new_intent, existing_intents) do
      {:ok, matched_intent} -> {:ok, matched_intent}
      :no_match -> find_circular_match(new_intent, existing_intents)
    end
  end

  defp find_direct_match(new_intent, existing_intents) do
    matching_intent = Enum.find(existing_intents, fn existing ->
      matches = existing.id != new_intent.id &&
      existing.status == "pending" &&
      existing.type == new_intent.type &&
      existing.source == new_intent.target &&  # Matching opposite directions
      existing.target == new_intent.source &&
      String.to_integer(existing.amount) >= String.to_integer(new_intent.amount)
      
      Logger.info("Checking direct match between #{existing.id} and #{new_intent.id}: #{matches}")
      matches
    end)

    case matching_intent do
      nil -> :no_match
      intent -> {:ok, intent}
    end
  end

  defp find_circular_match(new_intent, existing_intents) do
    pending_intents = Enum.filter(existing_intents, & &1.status == "pending")
    
    # Build a graph of transfers
    transfer_graph = build_transfer_graph([new_intent | pending_intents])
    
    # Find cycles in the graph that include the new intent
    case find_matching_cycle(transfer_graph, new_intent.source) do
      {:ok, cycle} ->
        Logger.info("Found circular match: #{inspect(cycle)}")
        # For now, just match with the intent that completes the shortest cycle
        matching_intent = Enum.find(pending_intents, fn intent ->
          intent.source == List.last(cycle) && intent.target == List.first(cycle)
        end)
        {:ok, matching_intent}
      :no_match ->
        :no_match
    end
  end

  defp build_transfer_graph(intents) do
    Enum.reduce(intents, %{}, fn intent, graph ->
      Map.update(graph, intent.source, [{intent.target, String.to_integer(intent.amount), intent}], fn existing ->
        [{intent.target, String.to_integer(intent.amount), intent} | existing]
      end)
    end)
  end

  defp find_matching_cycle(graph, current, visited \\ [], path \\ [], min_amount \\ nil)
  
  defp find_matching_cycle(graph, current, visited, path, min_amount) do
    new_path = [current | path]
    
    if current == List.first(path) && length(path) > 0 do
      {:ok, Enum.reverse(new_path)}
    else
      case Map.get(graph, current) do
        nil -> :no_match
        edges ->
          Enum.reduce_while(edges, :no_match, fn {target, amount, _intent}, acc ->
            if target not in visited do
              new_min = if min_amount, do: min(min_amount, amount), else: amount
              case find_matching_cycle(graph, target, [current | visited], new_path, new_min) do
                {:ok, cycle} -> {:halt, {:ok, cycle}}
                :no_match -> {:cont, acc}
              end
            else
              {:cont, acc}
            end
          end)
      end
    end
  end

  defp find_cycles(graph, start, visited \\ [], path \\ [], min_amount \\ nil) do
    if start in visited do
      if start == List.first(path) and length(path) > 2 do
        {:ok, Enum.reverse([start | path]), min_amount}
      else
        :no_match
      end
    else
      case Map.get(graph, start) do
        nil -> :no_match
        edges ->
          Enum.reduce_while(edges, :no_match, fn {target, amount, _intent}, acc ->
            new_min = if min_amount, do: min(min_amount, amount), else: amount
            case find_cycles(graph, target, [start | visited], [start | path], new_min) do
              {:ok, cycle, cycle_amount} -> {:halt, {:ok, cycle, cycle_amount}}
              :no_match -> {:cont, acc}
            end
          end)
      end
    end
  end
end 