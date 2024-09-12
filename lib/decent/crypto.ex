defmodule Decent.Crypto do
  @cipher_algo :chacha20_poly1305

  @ecc_algo :ecdh
  @ecc_curve :x25519

  @sign_algo :eddsa
  @sign_curve :ed25519

  @digest_algo :sha256

  @type ecc_private_key() :: <<_::32>>
  @type ecc_public_key() :: <<_::32>>

  @type sign_private_key() :: <<_::32>>
  @type sign_public_key() :: <<_::32>>

  @type hash_digest() :: <<_::32>>

  @spec generate_ecc_keypair() :: {ecc_private_key(), ecc_public_key()}
  def generate_ecc_keypair() do
    :crypto.generate_key(@ecc_algo, @ecc_curve)
  end

  @spec generate_sign_keypair() :: {sign_private_key(), sign_public_key()}
  def generate_sign_keypair(), do: :crypto.generate_key(@sign_algo, @sign_curve)

  @spec encrypt(iodata(), ecc_public_key()) :: {data, nonce, tag}
        when nonce: binary(), tag: binary(), data: binary()
  def encrypt(data, key) do
    nonce = :crypto.strong_rand_bytes(12)

    {enc_data, tag} =
      :crypto.crypto_one_time_aead(@cipher_algo, key, nonce, data, [], true)

    {enc_data, nonce, tag}
  end

  @spec decrypt(ecc_private_key(), binary(), binary(), binary()) :: binary()
  def decrypt(data, key, nonce, tag),
    do:
      :crypto.crypto_one_time_aead(
        @cipher_algo,
        key,
        nonce,
        data,
        [],
        tag,
        false
      )

  def sign(digest, key),
    do: :crypto.sign(@sign_algo, :none, {:digest, digest}, [key, @sign_curve])

  @spec hash(iodata()) :: hash_digest()
  def hash(data), do: :crypto.hash(@digest_algo, data)
end
