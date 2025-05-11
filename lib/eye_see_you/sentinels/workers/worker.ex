defmodule EyeSeeYou.Sentinels.Workers.SentinelWorker do
  @moduledoc """
  GenServer worker responsible for running sentinel protocol.
  """
  use GenServer
  require Logger

  alias EyeSeeYou.Sentinels.Protoccols.HttpProtocol
  alias EyeSeeYou.Sentinels.Repository
  alias EyeSeeYou.Sentinels.Services.StatusCache

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

    protocol = get_protocol(sentinel)
    result = protocol.perform_check(config)
    success = protocol.check_success?(result, config)
    check_result = Map.put(result, :success, success)

    StatusCache.set_check_result(sentinel.uuid, check_result)

    new_status = if check_result.success, do: :active, else: :error

    if new_status != state.status do
      updated_sentinel = %{sentinel | status: new_status}
      Repository.update_sentinel(updated_sentinel, %{status: new_status})
    end

    log_check_result(sentinel, check_result)

    %{state | last_check: check_result.timestamp, last_result: check_result, status: new_status}
  end

  defp get_protocol(_) do
    HttpProtocol
  end

  defp log_check_result(sentinel, result) do
    status = if result.success, do: "SUCCESS", else: "FAILURE"

    log_message = "Sentinel #{sentinel.name}(#{sentinel.uuid}): #{status}"

    expected = sentinel.config.data.expected_status

    "#{log_message} - HTTP #{result.status_code} (expected: #{expected}) in #{result.duration_ms}ms"

    Logger.info(log_message)
  end
end
