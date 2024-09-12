defmodule Decent.Sender do
  use GenServer

  defstruct peers_table: nil, socket: nil

  @type t() :: %__MODULE__{
          peers_table: :ets.table() | nil,
          socket: :inet.socket() | nil
        }

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init_state(initializer) do
    GenServer.cast(__MODULE__, {:init_state, initializer})
  end

  @impl true
  def init(nil) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast(
        {:init_state, %{socket: socket, peers_table: peers_table}},
        %__MODULE__{peers_table: nil, socket: nil} = state
      ) do
    {:noreply, %__MODULE__{state | peers_table: peers_table, socket: socket}}
  end
end
