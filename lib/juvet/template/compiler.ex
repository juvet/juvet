defmodule Juvet.Template.Compiler do
  def compile([]), do: ""

  def compile(ast), do: ast |> Enum.join("\n")
end
