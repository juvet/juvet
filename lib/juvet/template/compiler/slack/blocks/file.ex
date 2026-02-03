defmodule Juvet.Template.Compiler.Slack.Blocks.File do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :file, attributes: attrs}) do
    %{type: "file", external_id: attrs.external_id, source: attrs.source}
    |> maybe_put(:block_id, attrs[:block_id])
  end
end
