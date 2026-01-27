defmodule Juvet.Template.Compiler.Slack.Blocks.Divider do
  @moduledoc false

  def compile(%{element: :divider}), do: %{type: "divider"}
end
