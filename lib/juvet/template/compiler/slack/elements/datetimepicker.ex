defmodule Juvet.Template.Compiler.Slack.Elements.Datetimepicker do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :datetimepicker, attributes: attrs}) do
    %{type: "datetimepicker"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:initial_date_time, attrs[:initial_date_time])
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
  end
end
