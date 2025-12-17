defmodule Juvet.Template.Elements.Slack.HeaderElement do
  @moduledoc """
  Represents a Header element within a Slack context in a Juvet template.
  """

  alias Juvet.Template.Elements.Slack.TextElement

  @type t :: %__MODULE__{
          text: TextElement.t()
        }

  defstruct [:text]

  def new(attrs \\ []) do
    %__MODULE__{
      text: Keyword.get(attrs, :text) |> TextElement.new()
    }
  end
end
