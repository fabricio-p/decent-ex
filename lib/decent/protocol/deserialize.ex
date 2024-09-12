defmodule Decent.Protocol.Deserialize do
  require Decent.Protocol
  require Decent.MacroUtils
  require Decent.Protocol.{HandshakeReq, HandshakeAck, Encrypted, Text, Peers}

  import Decent.MacroUtils

  alias Decent.Protocol.{HandshakeReq, HandshakeAck, Encrypted, Text, Peers}

  @opaque partial_state() ::
            binary()
            | {:peers, [Peer.address()], non_neg_integer(), binary()}

  @type result() ::
          {:ok, Protocol.packet(), binary()}
          | {:partial, partial_state()}
          | {:error, any()}

  @spec to_packet(binary()) :: result()
  def to_packet(data)

  def to_packet(<<HandshakeReq.id()::8, pubkey::32-binary, rest::binary>>),
    do: {:ok, %HandshakeReq{pubkey: pubkey}, rest}

  def to_packet(
        <<HandshakeAck.id()::8, tag::16-binary, nonce::12-binary,
          varbin_pattern(roomkey, width: 8), rest::binary>>
      ),
      do:
        {:ok, %HandshakeAck{tag: tag, nonce: nonce, enc_roomkey: roomkey}, rest}

  def to_packet(
        <<Encrypted.id()::8, pubkey::32-binary, signature::64-binary,
          nonce::12-binary, tag::16-binary, varbin_pattern(data, width: 4 * 8),
          rest::binary>>
      ),
      do:
        {:ok,
         %Encrypted{
           pubkey: pubkey,
           signature: signature,
           nonce: nonce,
           tag: tag,
           data: data
         }, rest}

  def to_packet(
        <<Text.id()::8, varbin_pattern(content, width: 4 * 8), rest::binary>>
      ),
      do: {:ok, %Text{content: content}, rest}

  def to_packet(
        <<Peers.id()::8, num_peers::unit(8)-size(4)-little-unsigned-integer,
          rest::binary>>
      ) do
    parse_peers(num_peers, [], rest)
  end

  def to_packet(<<packet_id::8, _rest::binary>> = data)
      when packet_id in [
             HandshakeReq.id(),
             HandshakeAck.id(),
             Encrypted.id(),
             Text.id(),
           ],
      do: {:partial, data}

  @spec to_packet(partial_state(), binary()) :: result()
  def to_packet(partial_state, rest)

  def to_packet({:peers, peer_list, num_peers_left, data}, rest)
      when is_binary(rest) do
    parse_peers(num_peers_left, peer_list, data <> rest)
  end

  def to_packet(first_part, rest)
      when is_binary(first_part) and is_binary(rest) do
    to_packet(first_part <> rest)
  end

  defp parse_peers(0, acc, data), do: {:ok, %Peers{peer_list: acc}, data}

  defp parse_peers(
         num_peers_left,
         acc,
         <<peer_port::size(8 * 2 - 1)-little-unsigned-integer, ipv6_bit::1,
           rest::binary>> = data
       ) do
    ipv6? = ipv6_bit == 1

    if(ipv6?, do: parse_ipv6(rest), else: parse_ipv4(rest))
    |> case do
      {peer_ip, rest} ->
        parse_peers(num_peers_left - 1, [{peer_ip, peer_port} | acc], rest)

      :incomplete ->
        {:peers, acc, num_peers_left, data}
    end
  end

  defp parse_ipv4(
         <<ip0::8-little-unsigned-integer, ip1::8-little-unsigned-integer,
           ip2::8-little-unsigned-integer, ip3::8-little-unsigned-integer,
           rest::binary>>
       ),
       do: {{ip0, ip1, ip2, ip3}, rest}

  defp parse_ipv4(_data), do: :incomplete

  defp parse_ipv6(
         <<ip0::16-little-unsigned-integer, ip1::16-little-unsigned-integer,
           ip2::16-little-unsigned-integer, ip3::16-little-unsigned-integer,
           ip4::16-little-unsigned-integer, ip5::16-little-unsigned-integer,
           ip6::16-little-unsigned-integer, ip7::16-little-unsigned-integer,
           rest::binary>>
       ),
       do: {{ip0, ip1, ip2, ip3, ip4, ip5, ip6, ip7}, rest}

  defp parse_ipv6(_data), do: :incomplete
end
