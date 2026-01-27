defmodule Juvet.Template.Compiler.Slack.Blocks.Section do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack
  alias Juvet.Template.Compiler.Slack.Objects.Text

  def compile(%{element: :section, attributes: %{text: text} = attrs} = el) do
    %{type: "section", text: Text.compile(text, attrs)}
    |> maybe_put(:accessory, compile_child(el, :accessory))
  end

  defp compile_child(%{children: %{accessory: child}}, :accessory),
    do: Slack.compile_element(child)

  defp compile_child(_el, _key), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
