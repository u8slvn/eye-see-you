defmodule EyeSeeYou.Sentinels.Protoccols.HttpProtocol do
  @moduledoc """
  Implementation of the HTTP sentinel protocol.
  """
  @behaviour EyeSeeYou.Sentinels.Protocols.SentinelProtocol

  require Logger

  @default_http_options [
    recv_timeout: 15_000,
    timeout: 15_000,
    ssl: [verify: :verify_peer]
  ]

  def perform_check(config) do
    start_time = System.monotonic_time()
    result = make_http_request(config.data)
    end_time = System.monotonic_time()

    duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

    %{
      timestamp: DateTime.utc_now(),
      duration_ms: duration_ms,
      status_code: result.status_code,
      body: result.body,
      error: result.error
    }
  end

  @spec check_success?(any(), any()) :: boolean()
  def check_success?(result, config) do
    result.status_code == config.data.expected_status
  end

  defp make_http_request(data) do
    headers = format_headers(data.headers)
    method = String.to_atom(String.downcase(data.method))
    options = @default_http_options

    try do
      case do_request(method, data.url, headers, data.payload, options) do
        {:ok, %{status_code: status_code, body: body}} ->
          %{status_code: status_code, body: body, error: nil}

        {:error, %{reason: reason}} ->
          %{status_code: nil, body: nil, error: reason}
      end
    rescue
      e -> %{status_code: nil, body: nil, error: Exception.message(e)}
    end
  end

  defp do_request(:get, url, headers, _payload, options) do
    HTTPoison.get(url, headers, options)
  end

  defp do_request(method, url, headers, payload, options) when method in [:post, :put, :patch] do
    apply(HTTPoison, method, [url, payload || "", headers, options])
  end

  defp do_request(method, url, headers, _payload, options) do
    apply(HTTPoison, method, [url, headers, options])
  end

  defp format_headers(headers) when is_list(headers) do
    Enum.map(headers, fn header -> {header["name"], header["value"]} end)
  end

  defp format_headers(_), do: []
end
