defmodule Juvet.Template.Compiler.Slack.Elements.Button do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.{ConfirmationDialog, Text}

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :button, attributes: %{text: %{text: _} = text_attrs} = attrs} = el) do
    %{
      type: "button",
      text: Text.compile(text_attrs.text, Map.put_new(text_attrs, :type, :plain_text))
    }
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:confirm, compile_confirm(el))
  end

  def compile(%{element: :button, attributes: %{text: text} = attrs} = el) do
    %{type: "button", text: Text.compile(text, Map.put_new(attrs, :type, :plain_text))}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:confirm, compile_confirm(el))
  end

  defp compile_confirm(%{children: %{confirm: confirm}}),
    do: ConfirmationDialog.compile(confirm)

  defp compile_confirm(_), do: nil
end
