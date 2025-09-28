defmodule EyeSeeYou.Supervisor do
  use Supervisor
  require Logger

  def start_link({urls, check_interval}) do
    Supervisor.start_link(__MODULE__, {urls, check_interval}, name: __MODULE__)
  end

  @impl true
  def init({urls, check_interval}) do
    Logger.info("Starting EyeSeeYou monitors...")

    children = Enum.map(urls, fn url ->
      %{
        id: {:url_monitor, url},
        start: {EyeSeeYou.UrlMonitor, :start_link, [{url, check_interval}]},
        restart: :permanent,
        type: :worker
      }
    end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
