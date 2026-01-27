defmodule Juvet.Template.Compiler.Slack.Blocks.Section do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack
  alias Juvet.Template.Compiler.Slack.Objects.Text

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :section, attributes: %{text: text} = attrs} = el) do
    %{type: "section", text: Text.compile(text, attrs)}
    |> maybe_put(:accessory, compile_child(el, :accessory))
  end

  defp compile_child(%{children: %{accessory: child}}, :accessory),
    do: Slack.compile_element(child)

  defp compile_child(_el, _key), do: nil
end
