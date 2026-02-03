defmodule Juvet.Template.Compiler.Slack.Elements.StaticSelect do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.{Option, OptionGroup, Text}
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :static_select, attributes: attrs} = el) do
    %{type: "static_select"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:placeholder, compile_placeholder(attrs))
    |> put_options_or_groups(el)
    |> maybe_put(:initial_option, compile_initial_option(el))
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
  end

  defp compile_placeholder(%{placeholder: text}),
    do: Text.compile(text, %{type: :plain_text})

  defp compile_placeholder(_), do: nil

  defp put_options_or_groups(map, %{children: %{option_groups: groups}}) when is_list(groups),
    do: Map.put(map, :option_groups, Enum.map(groups, &OptionGroup.compile/1))

  defp put_options_or_groups(map, %{children: %{options: options}}) when is_list(options),
    do: Map.put(map, :options, Enum.map(options, &Option.compile/1))

  defp put_options_or_groups(map, _), do: map

  defp compile_initial_option(%{children: %{initial_option: opt}}),
    do: Option.compile(opt)

  defp compile_initial_option(_), do: nil
end
