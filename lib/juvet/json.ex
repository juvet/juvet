defmodule Juvet.JSON do
  @moduledoc """
  Encodes and decodes JSON with the configured library.

  ## Configuration

      config :juvet, :json_library, Jason

  Any module exposing `encode!/1`, `decode/2` and `decode!/2` works. Defaults to
  `Jason`. The `:json_encoder` key is deprecated but still read when
  `:json_library` is not set.
  """

  @spec decode(iodata(), keyword()) :: {:ok, term()} | {:error, term()}
  def decode(data, opts \\ []), do: library().decode(data, opts)

  @spec decode!(iodata(), keyword()) :: term()
  def decode!(data, opts \\ []), do: library().decode!(data, opts)

  @spec encode!(term()) :: String.t()
  def encode!(data), do: data |> library().encode!() |> IO.iodata_to_binary()

  @spec library() :: module()
  def library do
    Application.get_env(:juvet, :json_library) ||
      Application.get_env(:juvet, :json_encoder, Jason)
  end
end
