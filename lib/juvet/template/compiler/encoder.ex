defmodule Juvet.Template.Compiler.Encoder do
  @moduledoc """
  Behaviour for JSON encoding in the template compiler.

  Encoding goes through `Juvet.JSON`, so it uses the `:json_library` config:

      config :juvet, :json_library, Jason
  """

  @callback encode!(term()) :: String.t()

  @spec encode!(term()) :: String.t()
  defdelegate encode!(data), to: Juvet.JSON
end
