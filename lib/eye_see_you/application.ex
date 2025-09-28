defmodule EyeSeeYou.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    urls = get_urls_from_env()
    check_interval = get_check_interval()

    validate_config!()

    Logger.info("Starting EyeSeeYou for #{length(urls)} URL(s)")
    Logger.info("Check interval: #{check_interval} seconds")

    children = [
      {Registry, keys: :unique, name: EyeSeeYou.Registry},
      {EyeSeeYou.Supervisor, {urls, check_interval}}
    ]

    opts = [strategy: :one_for_one, name: EyeSeeYou.Application]
    Supervisor.start_link(children, opts)
  end

  defp get_urls_from_env do
    urls = case System.get_env("URLS") do
      nil -> []
      url_string ->
        url_string
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
    end

    if Enum.empty?(urls) do
      Logger.error("No URLs provided. Set the URLS environment variable.")
      System.halt(1)
    end

    urls
  end

  defp get_check_interval do
    case System.get_env("CHECK_INTERVAL", "300") do
      interval_str ->
        case Integer.parse(interval_str) do
          {interval, ""} when interval > 0 -> interval
          _ ->
            Logger.error("Invalid CHECK_INTERVAL. Using default 300 seconds.")
            300
        end
    end
  end

  defp validate_config! do
    required_vars = ["SMTP_SERVER", "EMAIL_USER", "EMAIL_PASSWORD", "RECIPIENT_EMAIL"]

    missing_vars = Enum.filter(required_vars, fn var ->
      is_nil(System.get_env(var))
    end)

    unless Enum.empty?(missing_vars) do
      Logger.error("Missing required environment variables: #{Enum.join(missing_vars, ", ")}")
      System.halt(1)
    end
  end
end
