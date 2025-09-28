defmodule EyeSeeYou.UrlMonitor do
   @moduledoc """
  GenServer that monitors a specific URL for changes and sends notifications.
  """
  use GenServer
  require Logger

  defstruct [:url, :check_interval, :current_hash]

  def start_link({url, check_interval}) do
    GenServer.start_link(__MODULE__, {url, check_interval}, name: via_tuple(url))
  end

  @impl true
  def init({url, check_interval}) do
    Logger.info("Starting monitor for #{url}")

    state = %__MODULE__{
      url: url,
      # Convert to milliseconds
      check_interval: check_interval * 1000,
      current_hash: nil
    }

    # Schedule first check
    schedule_check(0)

    {:ok, state}
  end

  @impl true
  def handle_info(:check_url, state) do
    new_state = check_url_for_changes(state)
    schedule_check(new_state.check_interval)
    {:noreply, new_state}
  end

  defp check_url_for_changes(state) do
    case fetch_url_content(state.url) do
      {:ok, content} ->
        new_hash = generate_hash(content)

        if state.current_hash && state.current_hash != new_hash do
          Logger.warning("Change detected for: #{state.url}")
          EyeSeeYou.Email.send_change_notification(state.url, state.current_hash, new_hash)
        else
          Logger.info("No changes detected for: #{state.url}")
        end

        %{state | current_hash: new_hash}

      {:error, reason} ->
        Logger.error("Failed to fetch #{state.url}: #{reason}")
        EyeSeeYou.Email.send_error_notification(state.url, reason)
        state
    end
  end

  defp fetch_url_content(url) do
    case HTTPoison.get(url, [], timeout: 30_000, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "HTTP #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp generate_hash(content) do
    :crypto.hash(:sha256, content) |> Base.encode16()
  end

  defp schedule_check(delay) do
    Process.send_after(self(), :check_url, delay)
  end

  defp via_tuple(url) do
    {:via, Registry, {EyeSeeYou.Registry, {:url_monitor, url}}}
  end
end
