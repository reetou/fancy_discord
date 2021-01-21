defmodule FancyDiscord.DeployLocker do
  use GenServer

  @in_progress_error {:error, :in_progress}

  def start_link(_) do
    {:ok, _} = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lock, app_id}, _from, state) do
    case Map.get(state, app_id) do
      nil -> {:reply, :ok, Map.put(state, app_id, DateTime.utc_now())}
      _ -> {:reply, @in_progress_error, state}
    end
  end

  @impl true
  def handle_call({:unlock, app_id}, _from, state) do
    {:reply, :ok, Map.drop(state, [app_id])}
  end

  @impl true
  def handle_call({:check, app_id}, _from, state) do
    case Map.get(state, app_id) do
      nil -> {:reply, :ok, state}
      _ -> {:reply, @in_progress_error, state}
    end
  end

  def lock(app_id) do
    GenServer.call(__MODULE__, {:lock, app_id})
  end

  def unlock(app_id) do
    GenServer.call(__MODULE__, {:unlock, app_id})
  end

  def check(app_id) do
    GenServer.call(__MODULE__, {:check, app_id})
  end
end
