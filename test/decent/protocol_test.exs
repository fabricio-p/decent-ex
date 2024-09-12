defmodule Decent.ProtocolTest do
  use ExUnit.Case
  doctest Decent.Protocol
  doctest Decent.Protocol.Serialize
  doctest Decent.Protocol.Deserialize

  require Decent.Protocol.{HandshakeReq, Peers}

  alias Decent.Protocol
  alias Decent.Protocol.{HandshakeReq, Peers}

  test "HandshakeReq full" do
    pubkey = :rand.bytes(32)

    assert {:ok, %HandshakeReq{pubkey: pubkey}, ""} ==
             %HandshakeReq{pubkey: pubkey}
             |> Protocol.serialize()
             |> Protocol.deserialize()
  end

  test "HandshakeReq extra" do
    pubkey = :rand.bytes(32)
    extra = :rand.bytes(11)

    assert {:ok, %HandshakeReq{pubkey: pubkey}, extra} ==
             %HandshakeReq{pubkey: pubkey}
             |> Protocol.serialize()
             |> Kernel.<>(extra)
             |> Protocol.deserialize()
  end

  test "HandshakeReq partial" do
    pubkey = :rand.bytes(32)
    partial_pubkey = binary_slice(pubkey, 0..-10//1)

    assert {:partial, <<HandshakeReq.id()::8, partial_pubkey::binary>>} ==
             %HandshakeReq{pubkey: pubkey}
             |> Protocol.serialize()
             |> binary_slice(0..-10//1)
             |> Protocol.deserialize()
  end

  test "Peers full" do
    peer_list =
      for _ <- 1..20 do
        ip = if random_do_ipv4?(), do: random_ipv4(), else: random_ipv6()
        port = random_port()
        {ip, port}
      end

    assert {:ok, %Peers{peer_list: peer_list}, ""} ==
             %Peers{peer_list: peer_list}
             |> Protocol.serialize()
             |> Protocol.deserialize()
  end

  defp random_do_ipv4?, do: :rand.uniform(2) == 1

  defp random_ipv4,
    do: Enum.map(1..4, fn _ -> :rand.uniform(0x100) - 1 end) |> List.to_tuple()

  defp random_ipv6,
    do:
      Enum.map(1..8, fn _ -> :rand.uniform(0x10000) - 1 end) |> List.to_tuple()

  # TODO: Specify that the max value for an address port is 0x7FFF
  defp random_port, do: :rand.uniform(0x7FFF - 0x400) + 0x400
end
