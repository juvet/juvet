defmodule Juvet.Template do
  alias Juvet.Template.Renderer

  defdelegate render(template), to: Renderer
  defdelegate render(template, assigns), to: Renderer
end
