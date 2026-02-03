defmodule Juvet.Template.Compiler.Slack.Blocks.Table do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :table, children: %{rows: rows}} = el) do
    attrs = el.attributes

    %{type: "table", rows: compile_rows(rows)}
    |> maybe_put(:column_settings, attrs[:column_settings])
    |> maybe_put(:block_id, attrs[:block_id])
  end

  defp compile_rows(rows) do
    Enum.map(rows, fn cells ->
      %{cells: Enum.map(cells, &compile_cell/1)}
    end)
  end

  defp compile_cell(%{element: :raw_text, attributes: %{text: text}}) do
    %{type: "raw_text", text: text}
  end

  defp compile_cell(%{element: :rich_text, children: %{elements: elements}}) do
    %{type: "rich_text", elements: Enum.map(elements, &Slack.compile_element/1)}
  end
end
