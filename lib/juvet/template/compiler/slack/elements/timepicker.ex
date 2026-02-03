defmodule Juvet.Template.Compiler.Slack.Elements.Timepicker do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :timepicker, attributes: attrs}) do
    %{type: "timepicker"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:initial_time, attrs[:initial_time])
    |> maybe_put(:placeholder, compile_placeholder(attrs))
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
    |> maybe_put(:timezone, attrs[:timezone])
  end

  defp compile_placeholder(%{placeholder: %{text: _} = attrs}),
    do: Text.compile(attrs.text, Map.put_new(attrs, :type, :plain_text))

  defp compile_placeholder(%{placeholder: text}) when is_binary(text),
    do: Text.compile(text, %{type: :plain_text})

  defp compile_placeholder(_), do: nil
end
