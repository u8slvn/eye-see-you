defmodule EyeSeeYouWeb.API.SentinelJSON do
  alias EyeSeeYou.Sentinels.Sentinel

  def index(%{sentinels: sentinels}) do
    %{data: for(sentinel <- sentinels, do: data(sentinel))}
  end

  def show(%{sentinel: sentinel}) do
    %{data: data(sentinel)}
  end

  defp data(%Sentinel{} = sentinel) do
    %{
      uuid: sentinel.uuid,
      name: sentinel.name,
      url: sentinel.url,
      interval: sentinel.interval,
      expected_status: sentinel.expected_status
    }
  end
end
