defmodule DeployHelloWeb.IntentLive do
  use DeployHelloWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :update)
    end

    intents = DeployHello.IntentStore.list_intents()
    {:ok, assign(socket, intents: intents, new_intent: %{amount: "", expiry: ""})}
  end

  @impl true
  def handle_event("create", %{"intent" => intent_params}, socket) do
    expiry = case intent_params["expiry"] do
      "" -> nil
      time_str -> 
        {minutes, _} = Integer.parse(time_str)
        DateTime.add(DateTime.utc_now(), minutes * 60, :second)
    end

    intent = %{
      id: System.unique_integer([:positive]),
      amount: String.to_integer(intent_params["amount"]),
      status: "pending",
      expiry: expiry,
      created_at: DateTime.utc_now()
    }

    DeployHello.IntentStore.store_intent(intent)
    intents = DeployHello.IntentStore.list_intents()
    {:noreply, assign(socket, intents: intents, new_intent: %{amount: "", expiry: ""})}
  end

  @impl true
  def handle_info(:update, socket) do
    intents = DeployHello.IntentStore.list_intents()
    |> Enum.filter(fn intent ->
      case intent.expiry do
        nil -> true
        expiry -> DateTime.compare(expiry, DateTime.utc_now()) == :gt
      end
    end)
    {:noreply, assign(socket, intents: intents)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <h1 class="text-2xl font-bold mb-4">Intents Explorer</h1>
      
      <div class="mb-8 p-4 bg-white rounded shadow">
        <h2 class="text-lg font-semibold mb-4">Create New Intent</h2>
        <form phx-submit="create" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Amount</label>
            <input type="number" name="intent[amount]" value={@new_intent.amount} required
                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Expiry (minutes from now, optional)</label>
            <input type="number" name="intent[expiry]" value={@new_intent.expiry} min="1"
                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" />
          </div>
          <button type="submit" class="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
            Create Intent
          </button>
        </form>
      </div>

      <div class="bg-white rounded shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Expiry</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created At</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for intent <- @intents do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= intent.id %></td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"><%= intent.amount %></td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{status_color(intent.status)}"}>
                    <%= intent.status %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= if intent.expiry do %>
                    <%= format_datetime(intent.expiry) %>
                  <% else %>
                    Never
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= format_datetime(intent.created_at) %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp status_color("pending"), do: "bg-yellow-100 text-yellow-800"
  defp status_color("matched"), do: "bg-green-100 text-green-800"
  defp status_color(_), do: "bg-gray-100 text-gray-800"

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end
end 