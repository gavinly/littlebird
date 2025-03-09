defmodule HelloWorld.IntentStore do
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
    GenServer.call(__MODULE__, :list_intents)
  end

  # Server callbacks

  @impl true
  def init(_args) do
    Logger.info("Starting intent store")
    :ets.new(@intent_store, [:set, :public, :named_table, :protected])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:store_intent, intent}, _from, state) do
    Logger.info("Storing intent in ETS: #{inspect(intent)}")
    :ets.insert(@intent_store, {intent.id, intent})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:list_intents, _from, state) do
    intents = :ets.tab2list(@intent_store) |> Enum.map(fn {_id, intent} -> intent end)
    Logger.info("Retrieved intents from ETS: #{inspect(intents)}")
    {:reply, intents, state}
  end
end 