defmodule EyeSeeYou.Sentinels.Workers.SentinelManager do
  @moduledoc """
  Manager for sentinel workers. Handles worker lifecycle but not persistence.
  """
  require Logger

  alias EyeSeeYou.Sentinels.Models.Sentinel
  alias EyeSeeYou.Sentinels.Repository
  alias EyeSeeYou.Sentinels.Workers.SentinelSupervisor
  alias EyeSeeYou.Sentinels.Workers.SentinelWorker

  @doc """
  Start a worker for a sentinel.
  """
  def start_sentinel_worker(%Sentinel{} = sentinel) do
    Logger.info("Starting worker for sentinel: #{sentinel.name} (#{sentinel.uuid})")
    SentinelSupervisor.start_worker(sentinel)
  end

  @doc """
  Stop a sentinel worker.
  """
  def stop_sentinel_worker(sentinel_uuid) do
    Logger.info("Stopping worker for sentinel: #{sentinel_uuid}")
    SentinelSupervisor.stop_worker(sentinel_uuid)
  end

  @doc """
  Restart a sentinel worker with updated configuration.
  """
  def restart_sentinel_worker(%Sentinel{} = sentinel) do
    Logger.info("Restarting worker for sentinel: #{sentinel.name} (#{sentinel.uuid})")
    stop_sentinel_worker(sentinel.uuid)
    start_sentinel_worker(sentinel)
  end

  @doc """
  Trigger an immediate check for a sentinel.
  """
  def force_check(sentinel_uuid) do
    Logger.info("Forcing check for sentinel: #{sentinel_uuid}")
    SentinelWorker.force_check(sentinel_uuid)
  end

  @doc """
  Initialize workers for all active sentinels.
  Called during application startup.
  """
  def initialize_workers do
    Logger.info("Initializing sentinel workers")

    Repository.list_sentinels()
    |> Enum.filter(fn sentinel -> sentinel.status == :active end)
    |> Enum.each(&start_sentinel_worker/1)
  end

  @doc """
  Update or create a worker based on sentinel status.
  Used after create/update operations.
  """
  def manage_worker_for_sentinel(%Sentinel{} = sentinel) do
    case sentinel.status do
      :active -> restart_sentinel_worker(sentinel)
      _ -> stop_sentinel_worker(sentinel.uuid)
    end

    {:ok, sentinel}
  end
end
