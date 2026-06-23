defmodule Juvet.Template.Compiler.Slack do
  @moduledoc """
  Compiles AST elements for the Slack platform into Block Kit JSON.

  Requires a `:slack.view` as the top-level element.
  Delegates to element-specific modules for compilation.
  """

  alias Juvet.Template.Compiler

  alias Juvet.Template.Compiler.Slack.Blocks.{
    Actions,
    Context,
    ContextActions,
    Divider,
    File,
    Header,
    Image,
    Input,
    Markdown,
    RichText,
    Section,
    Table,
    Video
  }

  alias Juvet.Template.Compiler.Slack.Elements.{
    Button,
    Checkboxes,
    Datepicker,
    Datetimepicker,
    EmailInput,
    FeedbackButtons,
    FileInput,
    IconButton,
    NumberInput,
    Overflow,
    PlainTextInput,
    RadioButtons,
    RichTextInput,
    RichTextList,
    RichTextPreformatted,
    RichTextQuote,
    RichTextSection,
    Select,
    Timepicker,
    UrlInput,
    WorkflowButton
  }

  alias Juvet.Template.Compiler.Slack.Objects.{
    ConfirmationDialog,
    ConversationFilter,
    DispatchActionConfig,
    Option,
    OptionGroup,
    SlackFile,
    Trigger,
    Workflow
  }

  alias Juvet.Template.Compiler.Slack.View

  @spec compile([Compiler.ast_element()]) :: map() | [map()]
  def compile([%{element: :view} = view]), do: View.compile(view)

  # A top-level `blocks:` template (no `.view` wrapper) compiles to a bare list
  # of blocks, suitable for a Slack message (`chat.postMessage`) rather than a
  # modal/home view.
  def compile([%{element: :blocks} = node]), do: compile_block_list(node)

  # A template must be a single `.view` or a top-level `blocks:` list — a loose
  # list of top-level elements is not a valid template.
  def compile(elements) when is_list(elements) do
    raise ArgumentError,
          "a Slack template must be a single `.view` or a top-level `blocks:` list, " <>
            "got top-level element(s): #{inspect(Enum.map(elements, &Map.get(&1, :element)))}"
  end

  defp compile_block_list(%{children: %{blocks: blocks}}) when is_list(blocks),
    do: Enum.map(blocks, &compile_element/1)

  defp compile_block_list(%{children: %{blocks: block}}) when is_map(block),
    do: [compile_element(block)]

  defp compile_block_list(_), do: []

  @doc false
  @spec compile_element(Compiler.ast_element() | map()) :: map()
  def compile_element(%{node_type: :code_block} = node) do
    %{__code_block__: true, code: node.code, line: node.line, column: node.column}
  end

  def compile_element(%{node_type: :for_loop} = node) do
    %{
      __for__: true,
      variable: node.variable,
      collection: node.collection,
      body: Enum.map(node.body, &compile_element/1)
    }
  end

  def compile_element(%{node_type: :if_block} = node) do
    %{
      __if__: true,
      condition: node.condition,
      then_body: Enum.map(node.then_body, &compile_element/1),
      else_body: compile_else_body(node.else_body)
    }
  end

  def compile_element(%{element: :actions} = el), do: Actions.compile(el)
  def compile_element(%{element: :button} = el), do: Button.compile(el)
  def compile_element(%{element: :checkboxes} = el), do: Checkboxes.compile(el)
  def compile_element(%{element: :datepicker} = el), do: Datepicker.compile(el)
  def compile_element(%{element: :datetimepicker} = el), do: Datetimepicker.compile(el)
  def compile_element(%{element: :email_input} = el), do: EmailInput.compile(el)
  def compile_element(%{element: :feedback_buttons} = el), do: FeedbackButtons.compile(el)
  def compile_element(%{element: :file_input} = el), do: FileInput.compile(el)
  def compile_element(%{element: :icon_button} = el), do: IconButton.compile(el)
  def compile_element(%{element: :number_input} = el), do: NumberInput.compile(el)
  def compile_element(%{element: :overflow} = el), do: Overflow.compile(el)
  def compile_element(%{element: :plain_text_input} = el), do: PlainTextInput.compile(el)
  def compile_element(%{element: :radio_buttons} = el), do: RadioButtons.compile(el)
  def compile_element(%{element: :rich_text_input} = el), do: RichTextInput.compile(el)
  def compile_element(%{element: :rich_text_list} = el), do: RichTextList.compile(el)

  def compile_element(%{element: :rich_text_preformatted} = el),
    do: RichTextPreformatted.compile(el)

  def compile_element(%{element: :rich_text_quote} = el), do: RichTextQuote.compile(el)
  def compile_element(%{element: :rich_text_section} = el), do: RichTextSection.compile(el)
  def compile_element(%{element: :timepicker} = el), do: Timepicker.compile(el)
  def compile_element(%{element: :select} = el), do: Select.compile(el)
  def compile_element(%{element: :url_input} = el), do: UrlInput.compile(el)
  def compile_element(%{element: :workflow_button} = el), do: WorkflowButton.compile(el)
  def compile_element(%{element: :confirm} = el), do: ConfirmationDialog.compile(el)

  def compile_element(%{element: :dispatch_action_config} = el),
    do: DispatchActionConfig.compile(el)

  def compile_element(%{element: :filter} = el), do: ConversationFilter.compile(el)
  def compile_element(%{element: :slack_file} = el), do: SlackFile.compile(el)
  def compile_element(%{element: :trigger} = el), do: Trigger.compile(el)
  def compile_element(%{element: :workflow} = el), do: Workflow.compile(el)
  def compile_element(%{element: :option} = el), do: Option.compile(el)
  def compile_element(%{element: :option_group} = el), do: OptionGroup.compile(el)
  def compile_element(%{element: :context} = el), do: Context.compile(el)
  def compile_element(%{element: :context_actions} = el), do: ContextActions.compile(el)
  def compile_element(%{element: :divider} = el), do: Divider.compile(el)
  def compile_element(%{element: :file} = el), do: File.compile(el)
  def compile_element(%{element: :header} = el), do: Header.compile(el)
  def compile_element(%{element: :image} = el), do: Image.compile(el)
  def compile_element(%{element: :input} = el), do: Input.compile(el)
  def compile_element(%{element: :markdown} = el), do: Markdown.compile(el)
  def compile_element(%{element: :rich_text} = el), do: RichText.compile(el)
  def compile_element(%{element: :section} = el), do: Section.compile(el)
  def compile_element(%{element: :table} = el), do: Table.compile(el)
  def compile_element(%{element: :video} = el), do: Video.compile(el)

  def compile_element(%{element: element, line: line, column: col}) do
    raise ArgumentError,
          "Unknown Slack element: #{inspect(element)} (line #{line}, column #{col})"
  end

  def compile_element(%{element: element}) do
    raise ArgumentError, "Unknown Slack element: #{inspect(element)}"
  end

  defp compile_else_body(nil), do: nil
  defp compile_else_body(list) when is_list(list), do: Enum.map(list, &compile_element/1)

  @doc false
  # Compiles an `if_block` that occupies a *singular* slot (e.g. a select's
  # `initial_option`) into an `__if_single__` marker. The regular `__if__`
  # marker resolves to a list at eval time, which is correct for list slots
  # (`options`, `initial_options`) but wrong for a slot that must hold a single
  # object or be omitted. `__if_single__` is resolved by `Juvet.Template.eval_map/2`.
  def compile_single_if(%{node_type: :if_block} = node) do
    %{
      __if_single__: true,
      condition: node.condition,
      then: single_branch(node.then_body),
      else: single_branch(node.else_body)
    }
  end

  defp single_branch(nil), do: nil
  defp single_branch([]), do: nil
  defp single_branch([element | _]), do: compile_element(element)
end
