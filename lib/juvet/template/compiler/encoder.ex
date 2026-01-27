defmodule Juvet.Template.Compiler.Encoder do
  @moduledoc """
  Behaviour for JSON encoding in the template compiler.

  ## Configuration

  Configure the encoder in your application config:

      config :juvet, :json_encoder, MyApp.CustomEncoder

  If not configured, automatically detects and uses Jason (preferred) or Poison.
  """

  @callback encode!(term()) :: String.t()

  # Suppress dialyzer warning for optional Jason dependency
  @dialyzer {:nowarn_function, default_encode!: 1}

  def encode!(data) do
    case Application.get_env(:juvet, :json_encoder) do
      nil -> default_encode!(data)
      encoder -> encoder.encode!(data)
    end
  end

  defp default_encode!(data) do
    if Code.ensure_loaded?(Jason) do
      Jason.encode!(data)
    else
      Poison.encode!(data)
    end
  end
end
