defmodule Juvet.Template.Compiler.Slack.Objects.ConfirmationDialog do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :confirm, attributes: attrs}) do
    %{
      title: %{type: "plain_text", text: attrs.title},
      text: %{type: "plain_text", text: attrs.text},
      confirm: %{type: "plain_text", text: attrs.confirm},
      deny: %{type: "plain_text", text: attrs.deny}
    }
    |> maybe_put(:style, attrs[:style])
  end
end
