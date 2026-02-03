defmodule Juvet.Template.Compiler.Slack.Blocks.RichText do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :rich_text, attributes: attrs} = el) do
    %{type: "rich_text", elements: compile_elements(el)}
    |> maybe_put(:block_id, attrs[:block_id])
  end

  defp compile_elements(%{children: %{elements: elements}}) when is_list(elements),
    do: Enum.map(elements, &Slack.compile_element/1)

  defp compile_elements(_el), do: []
end
