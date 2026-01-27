defmodule Juvet.Template.Compiler.Slack.Objects.Text do
  @moduledoc false

  def plain_text(text, attrs \\ %{}) do
    %{type: "plain_text", text: text}
    |> maybe_put(:emoji, attrs[:emoji])
  end

  def mrkdwn(text, attrs \\ %{}) do
    %{type: "mrkdwn", text: text}
    |> maybe_put(:verbatim, attrs[:verbatim])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
