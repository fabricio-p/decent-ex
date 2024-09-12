defmodule Decent.Protocol.Serialize do
  require Decent.Protocol
  require Decent.Protocol.{HandshakeReq, HandshakeAck, Encrypted, Text, Peers}

  alias Decent.Protocol.{HandshakeReq, HandshakeAck, Encrypted, Text, Peers}

  @spec to_binary(Protocol.packet()) :: binary()
  def to_binary(packet)

  def to_binary(%HandshakeReq{pubkey: pubkey}),
    do: <<HandshakeReq.id()::8, pubkey::32-binary>>

  # roomkey: possibly 32 bytes
  def to_binary(%HandshakeAck{tag: tag, nonce: nonce, enc_roomkey: roomkey}),
    do:
      <<HandshakeAck.id()::8, tag::16-binary, nonce::12-binary,
        varbin(roomkey)::binary>>

  def to_binary(%Encrypted{
        pubkey: pubkey,
        signature: signature,
        nonce: nonce,
        tag: tag,
        data: data
      }),
      do:
        <<Encrypted.id()::8, pubkey::32-binary, signature::64-binary,
          nonce::12-binary, tag::16-binary, varbin(data, 4)::binary>>

  def to_binary(%Text{content: content}),
    do: <<Text.id()::8, varbin(content, 4)::binary>>

  def to_binary(%Peers{peer_list: peer_list}) do
    {num_peers, peers_bin} =
      Enum.reduce(peer_list, {0, <<>>}, fn {ip, port}, {num_peers, peers_bin} ->
        ipv6_bit = if ipv6?(ip), do: 1, else: 0

        peer_bin =
          <<port::size(8 * 2 - 1)-little-unsigned-integer, ipv6_bit::1,
            serialize_ip(ip)::binary>>

        {num_peers + 1, <<peer_bin::binary, peers_bin::binary>>}
      end)

    <<Peers.id()::8, num_peers::unit(8)-size(4)-little-unsigned-integer,
      peers_bin::binary>>
  end

  defp varbin(bin, n_len_bytes \\ 1) do
    <<
      byte_size(bin)::unit(8)-size(n_len_bytes)-little-unsigned-integer,
      bin::binary
    >>
  end

  defp ipv6?({_, _, _, _}), do: false
  defp ipv6?({_, _, _, _, _, _, _, _}), do: true

  defp serialize_ip({ip0, ip1, ip2, ip3}),
    do:
      <<ip0::8-little-unsigned-integer, ip1::8-little-unsigned-integer,
        ip2::8-little-unsigned-integer, ip3::8-little-unsigned-integer>>

  defp serialize_ip({ip0, ip1, ip2, ip3, ip4, ip5, ip6, ip7}),
    do:
      <<ip0::16-little-unsigned-integer, ip1::16-little-unsigned-integer,
        ip2::16-little-unsigned-integer, ip3::16-little-unsigned-integer,
        ip4::16-little-unsigned-integer, ip5::16-little-unsigned-integer,
        ip6::16-little-unsigned-integer, ip7::16-little-unsigned-integer>>
end
