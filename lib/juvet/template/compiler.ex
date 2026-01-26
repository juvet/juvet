defmodule Juvet.Template.Compiler do
  @moduledoc false

  def compile([]), do: ""

  def compile(ast), do: ast |> Enum.join("\n")
end
