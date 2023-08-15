defmodule Juvet.SlackViewState do
  @moduledoc """
  Functions to operate on Slack's view responses and the view state passed back.
  """

  @spec parse(map()) :: map()
  def parse(view_state) do
    view_state
    |> Enum.reduce(%{}, fn {_block_id, block}, form ->
      block
      |> Map.to_list()
      |> Enum.reduce(form, fn {action_id, action}, reduced_form ->
        Map.merge(reduced_form, action_value(action_id, action))
      end)
    end)
  end

  defp action_value(action_id, action), do: %{action_id => form_value(action)}

  defp form_value(%{"selected_conversation" => value}), do: value
  defp form_value(%{"selected_date" => value}), do: value
  defp form_value(%{"selected_option" => %{"value" => value}}), do: value
  defp form_value(%{"selected_time" => value}), do: value

  defp form_value(%{"selected_options" => options}) do
    Enum.map(options, fn %{"value" => value} -> value end)
  end

  defp form_value(%{"value" => value}), do: value
end
