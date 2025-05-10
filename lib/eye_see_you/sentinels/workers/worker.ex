defmodule EyeSeeYou.Sentinels.Workers.SentinelWorker do
  @moduledoc """
  GenServer worker responsible for checking a sentinel's HTTP endpoint.
  """
  use GenServer
  require Logger

  alias EyeSeeYou.Sentinels.Repository
  alias EyeSeeYou.Sentinels.Services.StatusCache

  @default_http_options [
    recv_timeout: 15_000,
    timeout: 15_000,
    ssl: [verify: :verify_peer]
  ]

  def start_link(sentinel) do
    GenServer.start_link(__MODULE__, sentinel, name: via_tuple(sentinel.uuid))
  end

  def get_status(sentinel_uuid) do
    GenServer.call(via_tuple(sentinel_uuid), :get_status)
  end

  def force_check(sentinel_uuid) do
    GenServer.cast(via_tuple(sentinel_uuid), :check_now)
  end

  def update_sentinel(sentinel) do
    GenServer.cast(via_tuple(sentinel.uuid), {:update_sentinel, sentinel})
  end

  @impl true
  def init(sentinel) do
    # Schedule first check immediately after startup
    schedule_check(0)

    {:ok,
     %{
       sentinel: sentinel,
       last_check: nil,
       last_result: nil,
       status: :initializing
     }}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:check_now, state) do
    new_state = perform_check(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_sentinel, sentinel}, state) do
    # Reschedule with new interval if needed
    if sentinel.interval != state.sentinel.interval do
      schedule_check(sentinel.interval * 1000)
    end

    {:noreply, %{state | sentinel: sentinel}}
  end

  @impl true
  def handle_info(:check, state) do
    new_state = perform_check(state)
    # Schedule next check based on sentinel interval
    schedule_check(new_state.sentinel.interval * 1000)
    {:noreply, new_state}
  end

  defp via_tuple(sentinel_uuid) do
    {:via, Registry, {EyeSeeYou.SentinelRegistry, sentinel_uuid}}
  end

  defp schedule_check(delay_ms) do
    Process.send_after(self(), :check, delay_ms)
  end

  defp perform_check(state) do
    sentinel = state.sentinel
    config = sentinel.config
    start_time = System.monotonic_time()
    result = make_http_request(config.data)
    end_time = System.monotonic_time()

    duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

    check_result = %{
      timestamp: DateTime.utc_now(),
      duration_ms: duration_ms,
      status_code: result.status_code,
      success: result.status_code == config.data.expected_status,
      error: result.error
    }

    StatusCache.set_check_result(sentinel.uuid, check_result)

    # Update sentinel status if needed
    new_status = if check_result.success, do: :active, else: :error

    if new_status != state.status do
      # Update sentinel status in database if it changed
      updated_sentinel = %{sentinel | status: new_status}
      Repository.update_sentinel(updated_sentinel, %{status: new_status})
    end

    log_check_result(sentinel, check_result)

    %{state | last_check: check_result.timestamp, last_result: check_result, status: new_status}
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

  defp log_check_result(sentinel, result) do
    status = if result.success, do: "SUCCESS", else: "FAILURE"

    Logger.info(
      "Sentinel #{sentinel.name}(#{sentinel.uuid}): #{status} - " <>
        "HTTP #{result.status_code} (expected: #{sentinel.config.data.expected_status}) " <>
        "in #{result.duration_ms}ms"
    )
  end
end
