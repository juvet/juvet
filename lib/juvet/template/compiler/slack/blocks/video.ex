defmodule Juvet.Template.Compiler.Slack.Blocks.Video do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :video, attributes: attrs}) do
    %{
      type: "video",
      alt_text: attrs.alt_text,
      title: compile_title(attrs),
      thumbnail_url: attrs.thumbnail_url,
      video_url: attrs.video_url
    }
    |> maybe_put(:title_url, attrs[:title_url])
    |> maybe_put(:description, compile_description(attrs))
    |> maybe_put(:author_name, attrs[:author_name])
    |> maybe_put(:block_id, attrs[:block_id])
    |> maybe_put(:provider_name, attrs[:provider_name])
    |> maybe_put(:provider_icon_url, attrs[:provider_icon_url])
  end

  defp compile_title(%{title: %{text: _} = title_attrs}) do
    Text.compile(title_attrs.text, Map.put_new(title_attrs, :type, :plain_text))
  end

  defp compile_title(%{title: title}) do
    Text.compile(title, %{type: :plain_text})
  end

  defp compile_description(%{description: %{text: _} = desc_attrs}) do
    Text.compile(desc_attrs.text, Map.put_new(desc_attrs, :type, :plain_text))
  end

  defp compile_description(%{description: description}) when is_binary(description) do
    Text.compile(description, %{type: :plain_text})
  end

  defp compile_description(_attrs), do: nil
end
