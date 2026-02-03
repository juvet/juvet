defmodule Juvet.Template.Compiler.Slack.Objects.ConversationFilter do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :filter, attributes: attrs}) do
    %{}
    |> maybe_put(:include, attrs[:include])
    |> maybe_put(:exclude_external_shared_channels, attrs[:exclude_external_shared_channels])
    |> maybe_put(:exclude_bot_users, attrs[:exclude_bot_users])
  end
end
