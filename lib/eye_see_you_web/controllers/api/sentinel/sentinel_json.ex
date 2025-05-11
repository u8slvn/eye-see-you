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
      protocol: render_protocol(sentinel.protocol)
    }

    base
    |> maybe_add_field(sentinel, :last_check_result)
    |> maybe_add_field(sentinel, :last_check_timestamp)
  end

  defp render_protocol(protocol) do
    case protocol do
      nil ->
        nil

      protocol ->
        %{
          type: protocol.type,
          protocol: render_protocol_config(protocol.type, protocol.config)
        }
    end
  end

  defp render_protocol_config("http", config), do: render_http_config(config)

  defp render_http_config(config) do
    base = %{
      url: config.url,
      expected_status: config.expected_status
    }

    base
    |> maybe_add_field(config, :method, "GET")
    |> maybe_add_headers(config)
    |> maybe_add_field(config, :payload)
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

  defp maybe_add_headers(map, config) do
    headers = Map.get(config, :headers, [])

    if Enum.empty?(headers) do
      map
    else
      Map.put(map, :headers, headers)
    end
  end
end
