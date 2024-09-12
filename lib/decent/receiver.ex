defmodule Decent.Receiver do
  use GenServer

  # alias Decent.Peer

  defstruct [:port, :peers_table, socket: nil]

  @type t() :: %__MODULE__{
          port: :inet.port_number(),
          socket: :inet.socket() | nil,
          peers_table: :ets.table()
        }

  # table row: {Peer.address(), pid(), ref()}

  @spec start_link([opt]) :: GenServer.on_start()
        when opt:
               {:port, :inet.port_number()}
               | {:peers_table, atom()}
               | {:named_table, boolean()}
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def share_with_sender(), do: GenServer.cast(__MODULE__, :share_with_sender)

  @impl true
  def init(opts) do
    port = Keyword.fetch!(opts, :port)
    peers_table = Keyword.get(opts, :peers_table, :decent_peers)
    {:ok, socket} = open_port(port)
    table_options = [:set, :public, read_concurrency: true]

    table_options =
      if Keyword.get(opts, :named_table, false),
        do: [:named_table | table_options],
        else: table_options

    table = :ets.new(peers_table, table_options) |> dbg()

    {:ok, %__MODULE__{port: port, socket: socket, peers_table: table}}
  end

  @impl true
  def handle_cast(
        :share_with_sender,
        %__MODULE__{socket: socket, peers_table: peers_table} = state
      )
      when socket != nil do
    Decent.Sender.init_state(%{socket: socket, peers_table: peers_table})
    {:noreply, state}
  end

  # this is done so that we can throttle the data received from the socket and
  # distributed to the worker processes
  @impl true
  def handle_cast(
        :receive,
        %__MODULE__{socket: socket} = state
      ) do
    state =
      case :gen_udp.recv(socket, 0x400, 5) do
        {:ok, {peer_ip, peer_port, packet}} ->
          ping_next_socket_receive()
          handle_packet({peer_ip, peer_port}, packet, state)

        {:error, :timeout} ->
          set_active(socket, true)
          state
      end

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:udp, socket, peer_ip, peer_port, packet},
        %__MODULE__{socket: socket} = state
      ) do
    set_active(socket, false)
    ping_next_socket_receive()
    state = handle_packet({peer_ip, peer_port}, packet, state)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %__MODULE__{peers_table: nil, socket: nil}),
    do: :ignore

  @impl true
  def terminate(_reason, %__MODULE__{peers_table: peers_table, socket: socket}) do
    :ets.delete(peers_table)
    :gen_udp.close(socket)
    :ignore
  end

  def handle_packet(_peer_addr, _packet, state) do
    state
  end

  defp open_port(port) when port < 0x10000 do
    case :gen_udp.open(port, [:binary, active: true]) do
      {:ok, socket} -> {:ok, socket}
      {:error, :eaddrinuse} = err -> err
    end
  end

  defp open_port(_port), do: {:error, :invalid_port}

  defp set_active(socket, active?), do: :inet.setopts(socket, active: active?)

  defp ping_next_socket_receive() do
    GenServer.cast(__MODULE__, :receive)
  end
end
