defmodule EyeSeeYouWeb.API.Sentinel.SentinelJSON do
  alias EyeSeeYou.Sentinels.Models.Sentinel

  @doc """
  Renders a list of sentinels.
  """
  def index(%{sentinels: sentinels}) do
    %{data: for(sentinel <- sentinels, do: data(sentinel))}
  end

  @doc """
  Renders a single sentinel.
  """
  def show(%{sentinel: sentinel}) do
    %{data: data(sentinel)}
  end

  defp data(%Sentinel{} = sentinel) do
    base = %{
      uuid: sentinel.uuid,
      name: sentinel.name,
      interval: sentinel.interval,
      status: sentinel.status,
      config: render_config(sentinel.config)
    }

    base
    |> maybe_add_field(sentinel, :last_check_result)
    |> maybe_add_field(sentinel, :last_check_timestamp)
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

  defp render_config_data("http_request", data), do: render_http_request_data(data)

  defp render_http_request_data(data) do
    base = %{
      url: data.url,
      expected_status: data.expected_status
    }

    base
    |> maybe_add_field(data, :method, "GET")
    |> maybe_add_headers(data)
    |> maybe_add_field(data, :payload)
  end

  # Helper functions

  defp maybe_add_field(map, struct, field, default \\ nil) do
    value = Map.get(struct, field, default)

    if is_nil(value) || value == default do
      map
    else
      Map.put(map, field, value)
    end
  end

  defp maybe_add_headers(map, data) do
    headers = Map.get(data, :headers, [])

    if Enum.empty?(headers) do
      map
    else
      Map.put(map, :headers, headers)
    end
  end
end
