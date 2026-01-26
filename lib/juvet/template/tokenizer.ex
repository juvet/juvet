# A tokenizer converts the templates, which is simple io_data (string or list of strings)
# into a list of tokens that can be processed by the parser.
# Here are the tokenizer results for various templates:
#
# :slack.divider -> {:slack, :divider, []}
#
# :slack
#   :divider -> {:slack, :divider, []}
#
# :slack.header{text: "This is a header"} -> {:slack, :header, [text: "This is a header"]}
#
# :slack.header "This is a header" -> {:slack, :header, [text: "This is a header"]}
#
# :slack.header
#   text: "This is a header" -> {:slack, :header, [text: "This is a header"]}
#
# :slack.header
#   text:
#     text: "This is a header"
#     verbatium: true -> {:slack, :header, [text: "This is a header", verbatium: true]}
#
# :slack.section "This is a section"
#   accessory:
#     :image{image_url: "https://...", alt_text: "An image"}
# ->
#  {:slack, :section, [text: "This is a section"]}
#  {:slack, {:cont, 0}, {:acessory, []}}
#  {:slack, {:cont, 1}, {:image, [image_url: "...", alt_text: "An image"]}}
# ->
#   {:slack, :section, [text: "This is a section", accessory: {:image, [image_url: "...", alt_text: "An image"]}]}
#
# :slack.actions
#   elements:
#     :button{text: "Button #1", action_id: "button_1"}
#     :button{text: "Button #2", action_id: "button_2"}
#     :button "Button #3"
#       action_id: "button_3"
#     :image{image_url: "https://...", alt_text: "An image"}
# ->
#   {:slack, :actions, [elements: []]}
#   {:slack, {:cont, 0}, {:button, [text: "Button #1", action_id: "button_1"]}}
#   {:slack, {:cont, 0}, {:button, [text: "Button #2", action_id: "button_2"]}}
#   {:slack, {:cont, 0}, {:button, [text: "Button #3", action_id: "button_3"]}}
#   {:slack, {:cont, 0}, {:image, [image_url: "...", alt_text: "An image"]}}
# ->
#   {:slack, :actions, [elements: [{:slack, :button, [text: "Button #1", action_id: "button_1"]},...]]}
#
# Ideas:
# 1. There should not be specialized tokenizers for each platform. Instead, there should be a generic
#    tokenizer that can handle any platform based on configuration or context.
# 2. This is a tree structure. Each element can have child elements. The tokenizer should be able to
#    handle nested structures. We may want to process from the leaves up to the root.

defmodule Juvet.Template.Tokenizer do
  @moduledoc false

  alias Juvet.Template.Tokenizer.{ContinuationTokenizer, SlackTokenizer, UnknownTokenizer}

  # Start line with any tab or space followed by non-whitespace
  @indented_line_pattern ~r/^(\t|\s+)(\S+.*$)/

  def continuation_line?(line), do: String.match?(line, @indented_line_pattern)

  def tokenize(template, opts \\ [])

  def tokenize(template, opts) when is_binary(template),
    do:
      template
      |> split_lines()
      |> tokenize(opts)

  # The tokenize methods are where the context starts
  # The tokenize_line methods are where that vlue is required
  def tokenize([], _opts), do: []
  def tokenize([h | t], opts), do: [tokenize_line(h, opts) | tokenize(t, opts)]

  # TODO: The tokenize_line method should take conext or options as a return value
  # Currently it is a 3 element tuple of {platform, element, attributes}
  # {:slack, :divider, []}
  # {:slack. :header, []}
  # {:slack, {cont: 1}, [text: "This is a continuation line"]}
  def tokenize_line(line, opts \\ [])

  def tokenize_line(":slack." <> slack_line, _opts),
    do: List.to_tuple([:slack] ++ SlackTokenizer.tokenize_line(slack_line))

  def tokenize_line(line, opts) do
    # line |> IO.inspect(label: "unknown line")
    # opts |> IO.inspect(label: "opts")
    _ = {line, opts}

    # TODO: Detect it new element line -- e.g. starts with text: Something here
    # TODO: If these are attributes, how do we know what tokenizer to use?

    case continuation_line?(line) do
      true ->
        [_line, spacing, content] = Regex.run(@indented_line_pattern, line)

        List.to_tuple([:cont] ++ ContinuationTokenizer.tokenize_line(content, spacing: spacing))

      false ->
        List.to_tuple([:unknown] ++ UnknownTokenizer.tokenize_line(line, opts))
    end
  end

  # TODO: This is not too robust. Expand to handle more cases with white space, etc.
  defp split_lines(template),
    do:
      template
      |> String.split("\n", trim: true)
end
