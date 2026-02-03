defmodule Juvet.Template.Compiler.Slack.Blocks.Image do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Elements.Image, as: ImageElement

  def compile(%{element: :image} = el) do
    ImageElement.compile(el)
  end
end
