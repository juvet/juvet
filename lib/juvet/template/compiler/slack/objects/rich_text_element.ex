defmodule Juvet.Template.Compiler.Slack.Objects.RichTextElement do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :text, attributes: attrs}) do
    %{type: "text", text: attrs.text}
    |> maybe_put(:style, attrs[:style])
  end

  def compile(%{element: :link, attributes: attrs}) do
    %{type: "link", url: attrs.url}
    |> maybe_put(:text, attrs[:text])
    |> maybe_put(:style, attrs[:style])
    |> maybe_put(:unsafe, attrs[:unsafe])
  end

  def compile(%{element: :emoji, attributes: attrs}) do
    %{type: "emoji", name: attrs.name}
    |> maybe_put(:unicode, attrs[:unicode])
  end

  def compile(%{element: :channel, attributes: attrs}) do
    %{type: "channel", channel_id: attrs.channel_id}
    |> maybe_put(:style, attrs[:style])
  end

  def compile(%{element: :user, attributes: attrs}) do
    %{type: "user", user_id: attrs.user_id}
    |> maybe_put(:style, attrs[:style])
  end

  def compile(%{element: :usergroup, attributes: attrs}) do
    %{type: "usergroup", usergroup_id: attrs.usergroup_id}
    |> maybe_put(:style, attrs[:style])
  end

  def compile(%{element: :date, attributes: attrs}) do
    %{type: "date", timestamp: attrs.timestamp, format: attrs.format}
    |> maybe_put(:url, attrs[:url])
    |> maybe_put(:fallback, attrs[:fallback])
  end

  def compile(%{element: :broadcast, attributes: attrs}) do
    %{type: "broadcast", range: attrs.range}
  end

  def compile(%{element: :color, attributes: attrs}) do
    %{type: "color", value: attrs.value}
  end
end
