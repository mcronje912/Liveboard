defmodule Liveboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveboardWeb.Telemetry,
      Liveboard.Repo,
      {DNSCluster, query: Application.get_env(:liveboard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Liveboard.PubSub},
      # ADD PRESENCE HERE
      LiveboardWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: Liveboard.Finch},
      # Start a worker by calling: Liveboard.Worker.start_link(arg)
      # {Liveboard.Worker, arg},
      # Start to serve requests, typically the last entry
      LiveboardWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Liveboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
