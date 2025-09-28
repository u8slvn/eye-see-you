defmodule EyeSeeYou.Supervisor do
  @moduledoc """
  Main supervisor for URL monitors.
  """

  use Supervisor
  require Logger

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    urls = get_urls()
    check_interval = get_check_interval()

    Logger.info("Starting EyeSeeYou monitors...")

    children =
      urls
      |> Enum.map(fn url ->
        Logger.info("Starting monitor for #{url}")

        %{
          id: {:url_monitor, url},
          start: {EyeSeeYou.UrlMonitor, :start_link, [url, check_interval]},
          restart: :permanent,
          type: :worker
        }
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_urls do
    System.get_env("URLS", "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp get_check_interval do
    System.get_env("CHECK_INTERVAL", "60")
    |> String.to_integer()
    # Convert to milliseconds
    |> Kernel.*(1000)
  end
end
