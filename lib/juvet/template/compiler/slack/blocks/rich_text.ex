defmodule Juvet.Template.Compiler.Slack.Blocks.RichText do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :rich_text, attributes: attrs}) do
    %{type: "rich_text", elements: attrs.elements}
    |> maybe_put(:block_id, attrs[:block_id])
  end
end
