defmodule ExHackers.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ExHackers.Worker.start_link(arg)
      # {ExHackers.Worker, arg}
      {ExHackers.EchoServer, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExHackers.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
