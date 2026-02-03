defmodule Juvet.Template.Compiler.Slack.Elements.NumberInput do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :number_input, attributes: attrs}) do
    %{type: "number_input"}
    |> maybe_put(:is_decimal_allowed, attrs[:is_decimal_allowed])
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:initial_value, attrs[:initial_value])
    |> maybe_put(:min_value, attrs[:min_value])
    |> maybe_put(:max_value, attrs[:max_value])
    |> maybe_put(:placeholder, compile_placeholder(attrs))
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
  end

  defp compile_placeholder(%{placeholder: %{text: _} = attrs}),
    do: Text.compile(attrs.text, Map.put_new(attrs, :type, :plain_text))

  defp compile_placeholder(%{placeholder: text}) when is_binary(text),
    do: Text.compile(text, %{type: :plain_text})

  defp compile_placeholder(_), do: nil
end
