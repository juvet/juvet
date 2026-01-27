defmodule Juvet.Template.Compiler.Slack.Blocks.Actions do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack

  def compile(%{element: :actions} = el) do
    %{type: "actions", elements: compile_elements(el)}
  end

  defp compile_elements(%{children: %{elements: elements}}) when is_list(elements) do
    Enum.map(elements, &Slack.compile_element/1)
  end

  defp compile_elements(_el), do: []
end
