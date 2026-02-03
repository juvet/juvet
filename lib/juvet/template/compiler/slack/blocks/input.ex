defmodule Juvet.Template.Compiler.Slack.Blocks.Input do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack
  alias Juvet.Template.Compiler.Slack.Objects.Text

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :input, attributes: attrs, children: %{element: child}}) do
    %{type: "input", label: compile_label(attrs), element: Slack.compile_element(child)}
    |> maybe_put(:block_id, attrs[:block_id])
    |> maybe_put(:dispatch_action, attrs[:dispatch_action])
    |> maybe_put(:hint, compile_hint(attrs))
    |> maybe_put(:optional, attrs[:optional])
  end

  defp compile_label(%{label: %{text: _} = label_attrs}) do
    Text.compile(label_attrs.text, Map.put_new(label_attrs, :type, :plain_text))
  end

  defp compile_label(%{label: label}) do
    Text.compile(label, %{type: :plain_text})
  end

  defp compile_hint(%{hint: %{text: _} = hint_attrs}) do
    Text.compile(hint_attrs.text, Map.put_new(hint_attrs, :type, :plain_text))
  end

  defp compile_hint(%{hint: hint}) when is_binary(hint) do
    Text.compile(hint, %{type: :plain_text})
  end

  defp compile_hint(_attrs), do: nil
end
