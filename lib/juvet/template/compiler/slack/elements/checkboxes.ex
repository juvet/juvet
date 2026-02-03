defmodule Juvet.Template.Compiler.Slack.Elements.Checkboxes do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.{ConfirmationDialog, Option}
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :checkboxes, attributes: attrs} = el) do
    %{type: "checkboxes"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> put_options(el)
    |> put_initial_options(el)
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
    |> maybe_put(:confirm, compile_confirm(el))
  end

  defp put_options(map, %{children: %{options: options}}) when is_list(options),
    do: Map.put(map, :options, Enum.map(options, &Option.compile/1))

  defp put_options(map, %{children: %{options: %{} = option}}),
    do: Map.put(map, :options, [Option.compile(option)])

  defp put_options(map, _), do: map

  defp put_initial_options(map, %{children: %{initial_options: opts}}) when is_list(opts),
    do: Map.put(map, :initial_options, Enum.map(opts, &Option.compile/1))

  defp put_initial_options(map, _), do: map

  defp compile_confirm(%{children: %{confirm: confirm}}),
    do: ConfirmationDialog.compile(confirm)

  defp compile_confirm(_), do: nil
end
