defmodule Juvet.Template.Compiler.Slack.Objects.OptionGroup do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack

  def compile(%{element: :option_group, attributes: %{label: label}} = el) do
    %{label: %{type: "plain_text", text: label}, options: compile_options(el)}
  end

  defp compile_options(%{children: %{options: options}}) when is_list(options) or is_map(options),
    do: options |> List.wrap() |> Enum.map(&Slack.compile_element/1)

  defp compile_options(_), do: []
end
