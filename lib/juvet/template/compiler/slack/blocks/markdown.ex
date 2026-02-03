defmodule Juvet.Template.Compiler.Slack.Blocks.Markdown do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :markdown, attributes: attrs}) do
    %{type: "markdown", text: attrs.text}
    |> maybe_put(:block_id, attrs[:block_id])
  end
end
