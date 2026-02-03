defmodule Juvet.Template.Compiler.Slack.Elements.FileInput do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :file_input, attributes: attrs}) do
    %{type: "file_input"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:filetypes, attrs[:filetypes])
    |> maybe_put(:max_files, attrs[:max_files])
  end
end
