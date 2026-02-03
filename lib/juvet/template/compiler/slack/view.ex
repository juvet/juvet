defmodule Juvet.Template.Compiler.Slack.View do
  @moduledoc false

  alias Juvet.Template.Compiler.Encoder
  alias Juvet.Template.Compiler.Slack

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :view, attributes: attrs} = el) do
    %{type: to_string(attrs[:type])}
    |> maybe_put(:private_metadata, attrs[:private_metadata])
    |> Map.put(:blocks, compile_blocks(el))
    |> Encoder.encode!()
  end

  defp compile_blocks(%{children: %{blocks: blocks}}) when is_list(blocks) do
    Enum.map(blocks, &Slack.compile_element/1)
  end

  defp compile_blocks(%{children: %{blocks: block}}) when is_map(block) do
    [Slack.compile_element(block)]
  end

  defp compile_blocks(_), do: []
end
