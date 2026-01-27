defmodule Juvet.Template.Compiler.Encoder do
  @moduledoc """
  Behaviour for JSON encoding in the template compiler.

  ## Configuration

  Configure the encoder in your application config:

      config :juvet, :json_encoder, Juvet.Template.Compiler.Encoder.Jason

  Defaults to the Jason-based encoder if not configured.
  """

  @callback encode!(term()) :: String.t()

  def encode!(data) do
    encoder = Application.get_env(:juvet, :json_encoder, __MODULE__.Jason)
    encoder.encode!(data)
  end
end
