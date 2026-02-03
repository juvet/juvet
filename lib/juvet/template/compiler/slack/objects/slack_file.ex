defmodule Juvet.Template.Compiler.Slack.Objects.SlackFile do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :slack_file, attributes: attrs}) do
    %{}
    |> maybe_put(:url, attrs[:url])
    |> maybe_put(:id, attrs[:id])
  end
end
