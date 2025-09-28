defmodule EyeSeeYou.UrlMonitor do
  @moduledoc """
  GenServer that monitors a specific URL for changes and sends notifications.
  """

  use GenServer
  require Logger

  defstruct [:url, :check_interval, :current_hash]

  def start_link(url, check_interval) do
    GenServer.start_link(__MODULE__, {url, check_interval},
      name: {:via, Registry, {EyeSeeYou.Registry, {:url_monitor, url}}}
    )
  end

  @impl true
  def init({url, check_interval}) do
    state = %__MODULE__{
      url: url,
      check_interval: check_interval,
      current_hash: nil
    }

    # Schedule the first check
    Process.send_after(self(), :check_url, 1000)

    {:ok, state}
  end

  @impl true
  def handle_info(:check_url, state) do
    new_state = check_url_for_changes(state)

    # Schedule the next check
    Process.send_after(self(), :check_url, state.check_interval)

    {:noreply, new_state}
  end

  defp check_url_for_changes(state) do
    case HTTPoison.get(state.url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        new_hash = :crypto.hash(:md5, body) |> Base.encode16()

        if state.current_hash && state.current_hash != new_hash do
          Logger.info("Change detected for #{state.url}")
          EyeSeeYou.Email.send_change_notification(state.url, state.current_hash, new_hash)
        else
          Logger.info("No changes detected for: #{state.url}")
        end

        %{state | current_hash: new_hash}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.warning("HTTP #{status_code} for #{state.url}")
        state

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to fetch #{state.url}: #{inspect(reason)}")
        state

      # Gestion des erreurs de retry
      {:error, :retries_exceeded, details} ->
        Logger.error("Failed to fetch #{state.url} after retries: #{inspect(details)}")
        state
    end
  end
end
