defmodule Juvet.Template.Compiler.Slack.Objects.Workflow do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Trigger

  def compile(%{element: :workflow} = el) do
    %{trigger: compile_trigger(el)}
  end

  defp compile_trigger(%{children: %{trigger: trigger}}),
    do: Trigger.compile(trigger)
end
