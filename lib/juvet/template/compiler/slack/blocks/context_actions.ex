defmodule Juvet.Template.Compiler.Slack.Blocks.ContextActions do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack

  def compile(%{element: :context_actions} = el) do
    %{type: "context_actions", elements: compile_elements(el)}
  end

  defp compile_elements(%{children: %{elements: elements}}) when is_list(elements) do
    Enum.map(elements, &Slack.compile_element/1)
  end

  defp compile_elements(_el), do: []
end
