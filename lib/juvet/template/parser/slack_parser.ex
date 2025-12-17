defmodule Juvet.Template.Parser.SlackParser do
  @moduledoc false

  alias Juvet.Template.Elements.Slack.{Divider, HeaderElement}

  def parse_token({:divider, attrs}), do: Divider.new(attrs)
  def parse_token({:header, attrs}), do: HeaderElement.new(attrs)
end
