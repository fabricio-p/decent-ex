defmodule Decent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Decent.Receiver, port: 0xFAB},
      Decent.Sender
      # Starts a worker by calling: Decent.Worker.start_link(arg)
      # {Decent.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Decent.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
