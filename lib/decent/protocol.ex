defmodule Decent.Protocol do
  require Record

  require Decent.MacroUtils
  import Decent.MacroUtils

  defpacket(HandshakeReq, 1, pubkey: binary())

  defpacket(HandshakeAck, 2,
    tag: binary(),
    nonce: binary(),
    enc_roomkey: binary()
  )

  defpacket(Encrypted, 3,
    pubkey: binary(),
    signature: binary(),
    nonce: binary(),
    tag: binary(),
    data: binary()
  )

  defpacket(Text, 4, content: binary())
  defpacket(Peers, 5, peer_list: [Decent.Peer.address()])

  @type outer() :: HandshakeReq.t() | HandshakeAck.t() | Encrypted.t()
  @type inner() :: Text.t() | Peers.t()
  @type packet() :: outer() | inner()

  defdelegate serialize(packet), to: __MODULE__.Serialize, as: :to_binary
  defdelegate deserialize(data), to: __MODULE__.Deserialize, as: :to_packet

  defdelegate deserialize(part, rest),
    to: __MODULE__.Deserialize,
    as: :to_packet
end
