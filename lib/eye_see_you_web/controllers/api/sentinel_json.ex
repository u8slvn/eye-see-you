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
      interval: sentinel.interval,
      config: render_config(sentinel.config)
    }
  end

  defp render_config(config) do
    case config do
      nil ->
        nil

      config ->
        %{
          type: config.type,
          data: render_config_data(config.type, config.data)
        }
    end
  end

  defp render_config_data("simple_http_status", data) do
    %{
      url: data.url,
      expected_status: data.expected_status
    }
  end
end
