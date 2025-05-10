defmodule EyeSeeYou.Sentinels do
  @moduledoc """
  Sentinels context - coordinates persistence and worker management.
  """

  alias EyeSeeYou.Sentinels.Models.Sentinel
  alias EyeSeeYou.Sentinels.Repository
  alias EyeSeeYou.Sentinels.Workers.SentinelManager

  @doc """
  Initialize workers for all active sentinels.
  Called during application startup.
  """
  def init_sentinels do
    SentinelManager.initialize_workers()
  end

  @doc """
  Lists all sentinels.
  """
  def list_sentinels do
    Repository.list_sentinels()
  end

  @doc """
  Gets a sentinel by UUID.
  """
  def get_sentinel(uuid) do
    Repository.get_sentinel(uuid)
  end

  @doc """
  Creates a sentinel and starts its worker if active.
  """
  def create_sentinel(attrs) do
    with {:ok, sentinel} <- Repository.create_sentinel(attrs) do
      maybe_start_worker(sentinel)
    end
  end

  @doc """
  Updates a sentinel and manages its worker based on the new status.
  """
  def update_sentinel(%Sentinel{} = sentinel, attrs) do
    with {:ok, updated_sentinel} <- Repository.update_sentinel(sentinel, attrs) do
      SentinelManager.manage_worker_for_sentinel(updated_sentinel)
    end
  end

  @doc """
  Deletes a sentinel after stopping its worker.
  """
  def delete_sentinel(%Sentinel{} = sentinel) do
    SentinelManager.stop_sentinel_worker(sentinel.uuid)
    Repository.delete_sentinel(sentinel)
  end

  @doc """
  Force a check for a sentinel.
  """
  def force_check(uuid) do
    SentinelManager.force_check(uuid)
  end

  defp maybe_start_worker(%Sentinel{status: :active} = sentinel) do
    SentinelManager.start_sentinel_worker(sentinel)
    {:ok, sentinel}
  end

  defp maybe_start_worker(sentinel), do: {:ok, sentinel}
end
