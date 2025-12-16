defmodule Juvet.Template.Renderer do
  def render(template, assigns \\ []) do
    template
    |> EEx.eval_string(assigns)
  end
end
