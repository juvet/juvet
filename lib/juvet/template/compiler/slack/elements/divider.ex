defmodule Juvet.Template.Compiler.Slack.Elements.Divider do
  @moduledoc false

  def compile(%{element: :divider}), do: %{type: "divider"}
end
