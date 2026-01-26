defmodule Juvet.Template do
  @moduledoc false

  alias Juvet.Template.Renderer

  defdelegate render(template), to: Renderer
  defdelegate render(template, assigns), to: Renderer
end
