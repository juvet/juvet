defmodule Juvet.Template.Elements.Slack.Divider do
  @moduledoc """
  Represents a Slack divider element in a Juvet template.
  """

  @type t :: %__MODULE__{}

  defstruct []

  def new(_attrs), do: %__MODULE__{}
end
