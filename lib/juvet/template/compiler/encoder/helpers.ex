defmodule Juvet.Template.Compiler.Encoder.Helpers do
  @moduledoc false

  def maybe_put(%{} = map, _key, nil), do: map
  def maybe_put(%{} = map, key, value), do: Map.put(map, key, value)
end
