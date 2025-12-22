defmodule Juvet.Template.Elements.Slack.TextElement do
  @moduledoc """
  Represents a Text element within another Slack Element context in a Juvet template.

  # TODO: Should `composite` elements be within their own namespace as they are considered 'building blocks'.??
  # Meaning, they can compose higher level 'block elements'.
  # TODO: I wonder if we should namespace BlockKit? -> I think that makes the most sense
  #
  # Juvet.Template.Slack.BlockKit.Composite.TextElement -> https://docs.slack.dev/reference/block-kit/composition-objects/text-object/
  #   -> Juvet.Template.Slack.BlockKit.Objects.TextObject !!!!
  #
  # Juvet.Template.Elements.Slack -> Juvet.Template.Slack.BlockKit
  # Juvet.Template.Elements.Slack.HeaderElement -> Juvet.Template.Slack.BlockKit.Blocks.HeaderBlock -> https://docs.slack.dev/reference/block-kit/blocks/header-block/
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
