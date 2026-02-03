defmodule Juvet.Template.Compiler.Slack.Objects.DispatchActionConfig do
  @moduledoc false

  def compile(%{element: :dispatch_action_config, attributes: attrs}) do
    %{trigger_actions_on: List.wrap(attrs.trigger_actions_on)}
  end
end
