defmodule EyeSeeYou.Sentinels.Workers.SentinelSupervisor do
  @moduledoc """
  Dynamic supervisor for sentinel workers.
  """
  use DynamicSupervisor

  alias EyeSeeYou.Sentinels.Workers.SentinelWorker

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a new sentinel worker for the given sentinel.
  """
  def start_worker(sentinel) do
    child_spec = {SentinelWorker, sentinel}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Stop the worker for a specific sentinel.
  """
  def stop_worker(sentinel_uuid) do
    case Registry.lookup(EyeSeeYou.SentinelRegistry, sentinel_uuid) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      [] ->
        {:error, :not_found}
    end
  end
end
