defmodule EyeSeeYou.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EyeSeeYouWeb.Telemetry,
      EyeSeeYou.Repo,
      {DNSCluster, query: Application.get_env(:eye_see_you, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EyeSeeYou.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: EyeSeeYou.Finch},
      # Start a worker by calling: EyeSeeYou.Worker.start_link(arg)
      # {EyeSeeYou.Worker, arg},
      # Start to serve requests, typically the last entry
      EyeSeeYouWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EyeSeeYou.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EyeSeeYouWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
