defmodule Juvet.Template.Elements.Slack.DividerElement do
  @moduledoc """
  Represents a Divider element within a Slack context in a Juvet template.
  """

  @type t :: %__MODULE__{}

  defstruct []

  def new(_attrs \\ []), do: %__MODULE__{}
end
