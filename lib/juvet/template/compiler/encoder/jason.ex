defmodule Juvet.Template.Compiler.Encoder.Jason do
  @moduledoc false
  @behaviour Juvet.Template.Compiler.Encoder

  @impl true
  def encode!(data), do: Jason.encode!(data)
end
