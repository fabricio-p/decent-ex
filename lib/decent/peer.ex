defmodule Decent.Peer do
  use GenServer
  # alias Decent.{Receiver, Sender}

  defstruct [:address, stage: :start]

  @type address() :: {:inet.ip_address(), :inet.port_number()}
  @type t() :: %__MODULE__{
          address: address(),
          stage: :start | :shaking_hands | :normal
        }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    address = Keyword.fetch!(opts, :address)
    {:ok, %__MODULE__{address: address}}
  end

  @impl true
  def handle_cast(
        :handle_packet,
        %__MODULE__{address: _address, stage: :new} = state
      ) do
    {:noreply, %__MODULE__{state | stage: :shaking_hands}}
  end
end
