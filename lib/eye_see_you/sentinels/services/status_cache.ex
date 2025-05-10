defmodule EyeSeeYou.Sentinels.Services.StatusCache do
  @moduledoc """
  Cache for sentinel status information.
  """

  @cache_name :sentinel_status_cache

  def child_spec(_opts) do
    %{
      id: Cachex,
      start: {Cachex, :start_link, [@cache_name, []]}
    }
  end

  @doc """
  Get the status for a sentinel.
  """
  def get_status(uuid) when is_binary(uuid) do
    case Cachex.get(@cache_name, target_key(uuid)) do
      {:ok, nil} -> nil
      {:ok, value} -> value
    end
  end

  @doc """
  Set the status for a sentinel.
  """
  def set_status(uuid, status) when is_binary(uuid) and is_integer(status) do
    {:ok, _} = Cachex.put(@cache_name, target_key(uuid), status)
    :ok
  end

  @doc """
  Store the last check result with timestamp.
  """
  def set_check_result(uuid, result) when is_binary(uuid) do
    timestamp = DateTime.utc_now()
    {:ok, _} = Cachex.put(@cache_name, result_key(uuid), {result, timestamp})
    :ok
  end

  @doc """
  Get the last check result with timestamp.
  """
  def get_check_result(uuid) when is_binary(uuid) do
    case Cachex.get(@cache_name, result_key(uuid)) do
      {:ok, nil} -> nil
      {:ok, value} -> value
    end
  end

  @doc """
  Get all cached statuses.
  """
  def get_all_statuses do
    {:ok, keys} = Cachex.keys(@cache_name)

    keys
    |> Enum.filter(&target_key?/1)
    |> Enum.map(fn key ->
      uuid = extract_uuid_from_target_key(key)
      {:ok, status} = Cachex.get(@cache_name, key)
      {uuid, status}
    end)
    |> Map.new()
  end

  # Helper functions
  defp target_key(uuid), do: "target:#{uuid}"
  defp result_key(uuid), do: "result:#{uuid}"

  defp target_key?(key) when is_binary(key), do: String.starts_with?(key, "target:")
  defp target_key?(_), do: false

  defp extract_uuid_from_target_key("target:" <> uuid), do: uuid
end
