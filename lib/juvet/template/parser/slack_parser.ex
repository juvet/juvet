defmodule Juvet.Template.Parser.SlackParser do
  @moduledoc false

  alias Juvet.Template.Elements.Slack.{DividerElement, HeaderElement}

  def parse_token({:divider, attrs}), do: DividerElement.new(attrs)
  def parse_token({:header, attrs}), do: HeaderElement.new(attrs)
end
