defmodule Juvet.Template.Compiler.Slack.View do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack
  alias Juvet.Template.Compiler.Slack.Objects.Text

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :view, attributes: attrs} = el) do
    %{type: to_string(attrs[:type])}
    |> maybe_put(:callback_id, attrs[:callback_id])
    |> maybe_put(:title, compile_text(attrs[:title]))
    |> maybe_put(:submit, compile_text(attrs[:submit]))
    |> maybe_put(:close, compile_text(attrs[:close]))
    |> maybe_put(:private_metadata, attrs[:private_metadata])
    |> maybe_put(:clear_on_close, attrs[:clear_on_close])
    |> maybe_put(:notify_on_close, attrs[:notify_on_close])
    |> maybe_put(:external_id, attrs[:external_id])
    |> maybe_put(:submit_disabled, attrs[:submit_disabled])
    |> Map.put(:blocks, compile_blocks(el))
  end

  defp compile_text(nil), do: nil

  defp compile_text(%{text: text} = attrs),
    do: Text.compile(text, Map.put_new(attrs, :type, :plain_text))

  defp compile_text(text) when is_binary(text),
    do: Text.compile(text, %{type: :plain_text})

  defp compile_blocks(%{children: %{blocks: blocks}}) when is_list(blocks) do
    Enum.map(blocks, &Slack.compile_element/1)
  end

  defp compile_blocks(%{children: %{blocks: block}}) when is_map(block) do
    [Slack.compile_element(block)]
  end

  defp compile_blocks(_), do: []
end
