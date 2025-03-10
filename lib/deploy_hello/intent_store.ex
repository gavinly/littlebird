defmodule DeployHello.IntentStore do
  use GenServer
  require Logger

  @intent_store :intent_store

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def store_intent(intent) do
    GenServer.call(__MODULE__, {:store_intent, intent})
  end

  def list_intents do
    try do
      :ets.tab2list(@intent_store)
      |> Enum.map(fn {_id, intent} -> intent end)
      |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    rescue
      _ -> []
    end
  end

  def add_intent(intent) do
    GenServer.cast(__MODULE__, {:add_intent, intent})
  end

  # Server callbacks

  @impl true
  def init(_args) do
    Logger.info("Starting intent store")
    :ets.new(@intent_store, [:set, :public, :named_table])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:store_intent, intent}, _from, state) do
    Logger.info("Storing intent: #{inspect(intent)}")
    :ets.insert(@intent_store, {intent.id, intent})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:list_intents, _from, state) do
    intents = list_intents()
    Logger.info("Retrieved #{length(intents)} intents")
    {:reply, intents, state}
  end

  @impl true
  def handle_cast({:add_intent, intent}, state) do
    Logger.info("Adding intent via cast: #{inspect(intent)}")
    :ets.insert(@intent_store, {intent.id, intent})
    {:noreply, state}
  end

  # Helper functions
  
  def clear_expired_intents do
    now = DateTime.utc_now()
    list_intents()
    |> Enum.each(fn intent ->
      if intent.expiry && DateTime.compare(intent.expiry, now) == :lt do
        :ets.delete(@intent_store, intent.id)
      end
    end)
  end
end 