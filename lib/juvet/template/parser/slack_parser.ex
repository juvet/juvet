defmodule Juvet.Template.Parser.SlackParser do
  @moduledoc false

  alias Juvet.Template.Elements.Slack.{Divider}

  def parse_token({:divider, attrs}), do: Divider.new(attrs)
end
