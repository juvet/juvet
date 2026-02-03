defmodule Juvet.Template.Compiler.Slack.Elements.Datetimepicker do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.ConfirmationDialog
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :datetimepicker, attributes: attrs} = el) do
    %{type: "datetimepicker"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:initial_date_time, attrs[:initial_date_time])
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
    |> maybe_put(:confirm, compile_confirm(el))
  end

  defp compile_confirm(%{children: %{confirm: confirm}}),
    do: ConfirmationDialog.compile(confirm)

  defp compile_confirm(_), do: nil
end
