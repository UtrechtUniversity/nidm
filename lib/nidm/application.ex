defmodule Nidm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Nidm.Repo,
      # Start the Telemetry supervisor
      NidmWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Nidm.PubSub},
      # Start the Endpoint (http/https)
      NidmWeb.Endpoint,
      # Start a worker by calling: Nidm.Worker.start_link(arg)
      # {Nidm.Worker, arg}

      # Supervisor for my GenServers
      Nidm.GenServers.GameSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nidm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NidmWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
