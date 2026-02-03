defmodule Juvet.Template.Compiler.Slack.Elements.RadioButtons do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.{ConfirmationDialog, Option}
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :radio_buttons, attributes: attrs} = el) do
    %{type: "radio_buttons"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> put_options(el)
    |> put_initial_option(el)
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
    |> maybe_put(:confirm, compile_confirm(el))
  end

  defp put_options(map, %{children: %{options: options}}) when is_list(options),
    do: Map.put(map, :options, Enum.map(options, &Option.compile/1))

  defp put_options(map, %{children: %{options: %{} = option}}),
    do: Map.put(map, :options, [Option.compile(option)])

  defp put_options(map, _), do: map

  defp put_initial_option(map, %{children: %{initial_option: opt}}),
    do: Map.put(map, :initial_option, Option.compile(opt))

  defp put_initial_option(map, _), do: map

  defp compile_confirm(%{children: %{confirm: confirm}}),
    do: ConfirmationDialog.compile(confirm)

  defp compile_confirm(_), do: nil
end
