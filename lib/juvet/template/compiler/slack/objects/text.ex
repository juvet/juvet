defmodule Juvet.Template.Compiler.Slack.Objects.Text do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(text, %{type: :plain_text} = attrs) do
    %{type: "plain_text", text: text}
    |> maybe_put(:emoji, attrs[:emoji])
  end

  def compile(text, %{type: :mrkdwn} = attrs) do
    %{type: "mrkdwn", text: text}
    |> maybe_put(:verbatim, attrs[:verbatim])
  end

  def compile(text, attrs) do
    compile(text, Map.put(attrs, :type, :mrkdwn))
  end
end
