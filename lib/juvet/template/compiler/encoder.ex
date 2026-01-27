defmodule Juvet.Template.Compiler.Encoder do
  @moduledoc """
  Behaviour for JSON encoding in the template compiler.

  ## Configuration

  Configure the encoder in your application config:

      config :juvet, :json_encoder, Jason

  Defaults to Poison if not configured.
  """

  @callback encode!(term()) :: String.t()

  @spec encode!(term()) :: String.t()
  def encode!(data) do
    encoder().encode!(data)
  end

  defp encoder do
    Application.get_env(:juvet, :json_encoder, Poison)
  end
end
