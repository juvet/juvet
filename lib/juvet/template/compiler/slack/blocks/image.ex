defmodule Juvet.Template.Compiler.Slack.Blocks.Image do
  @moduledoc false

  def compile(%{element: :image, attributes: attrs}) do
    %{type: "image"}
    |> maybe_put(:image_url, attrs[:url])
    |> maybe_put(:alt_text, attrs[:alt_text])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
