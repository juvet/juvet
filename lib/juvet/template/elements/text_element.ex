defmodule Juvet.Template.Elements.Slack.TextElement do
  @moduledoc """
  Represents a Text element within another Slack Element context in a Juvet template.
  """

  @type t :: %__MODULE__{
          text: String.t(),
          contains_emoji?: boolean(),
          type: :plain_text | :markdown,
          verbatim?: boolean()
        }

  defstruct [:text, contains_emoji?: false, type: :markdown, verbatim?: false]

  def new(attrs \\ [])

  def new(text) when is_binary(text),
    do: %__MODULE__{text: text}

  def new(attrs) when is_list(attrs),
    do: %__MODULE__{
      text: Keyword.get(attrs, :text),
      contains_emoji?: Keyword.get(attrs, :contains_emoji?),
      type: Keyword.get(attrs, :type),
      verbatim?: Keyword.get(attrs, :verbatim?)
    }
end
