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
    Section
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
    Select,
    Timepicker,
    UrlInput,
    WorkflowButton
  }

  alias Juvet.Template.Compiler.Slack.Objects.{ConversationFilter, Option, OptionGroup}
  alias Juvet.Template.Compiler.Slack.View

  @spec compile([Compiler.ast_element()]) :: map()
  def compile([%{element: :view} = view]), do: View.compile(view)

  @doc false
  @spec compile_element(Compiler.ast_element()) :: map()
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
  def compile_element(%{element: :timepicker} = el), do: Timepicker.compile(el)
  def compile_element(%{element: :select} = el), do: Select.compile(el)
  def compile_element(%{element: :url_input} = el), do: UrlInput.compile(el)
  def compile_element(%{element: :workflow_button} = el), do: WorkflowButton.compile(el)
  def compile_element(%{element: :filter} = el), do: ConversationFilter.compile(el)
  def compile_element(%{element: :option} = el), do: Option.compile(el)
  def compile_element(%{element: :option_group} = el), do: OptionGroup.compile(el)
  def compile_element(%{element: :context} = el), do: Context.compile(el)
  def compile_element(%{element: :context_actions} = el), do: ContextActions.compile(el)
  def compile_element(%{element: :divider} = el), do: Divider.compile(el)
  def compile_element(%{element: :file} = el), do: File.compile(el)
  def compile_element(%{element: :header} = el), do: Header.compile(el)
  def compile_element(%{element: :image} = el), do: Image.compile(el)
  def compile_element(%{element: :input} = el), do: Input.compile(el)
  def compile_element(%{element: :section} = el), do: Section.compile(el)

  def compile_element(%{element: element, line: line, column: col}) do
    raise ArgumentError,
          "Unknown Slack element: #{inspect(element)} (line #{line}, column #{col})"
  end

  def compile_element(%{element: element}) do
    raise ArgumentError, "Unknown Slack element: #{inspect(element)}"
  end
end
