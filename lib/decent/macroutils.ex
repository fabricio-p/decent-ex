defmodule Decent.MacroUtils do
  defmacro defpacket(name, bin_id, fields) do
    keys = Enum.map(fields, fn {key, _type} -> key end)

    type =
      {:%, [],
       [
         {:__MODULE__, [], __MODULE__},
         {:%{}, [], fields}
       ]}

    quote do
      defmodule unquote(name) do
        defstruct unquote(keys)
        @type t() :: unquote(type)
        defmacro id, do: unquote(bin_id)
      end
    end
  end

  defmacro varbin_pattern({bare_bin_name, _, _} = bin_name, length_opts) do
    len_width = Keyword.fetch!(length_opts, :width)
    bare_len_endian = Keyword.get(length_opts, :endian, :little)

    bin_len_name =
      Keyword.get(length_opts, :name, {:"#{bare_bin_name}_len", [], nil})

    len_endian = {bare_len_endian, [], nil}

    if bare_len_endian not in ~w[little big]a,
      do: raise("Endianness can be only one of `:little`, `:big`")

    quote do
      <<unquote(bin_len_name)::size(unquote(len_width))-unquote(len_endian)-unsigned-integer,
        unquote(bin_name)::size(unquote(bin_len_name))-binary>>
    end
  end
end
