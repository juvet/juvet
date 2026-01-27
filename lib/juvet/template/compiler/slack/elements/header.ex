defmodule Juvet.Template.Compiler.Slack.Elements.Header do
  @moduledoc false

  def compile(%{element: :header, attributes: %{text: text} = attrs}) do
    %{type: "header", text: plain_text_object(text, attrs)}
  end

  defp plain_text_object(text, attrs) do
    %{type: "plain_text", text: text}
    |> maybe_put(:emoji, attrs[:emoji])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
