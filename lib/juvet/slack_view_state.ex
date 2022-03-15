defmodule Juvet.SlackViewState do
  @moduledoc """
  Functions to operate on Slack's view responses and the view state passed back.
  """

  def parse(view_state) do
    view_state
    |> Enum.reduce(%{}, fn {_block_id, block}, form ->
      [{action_id, action}] = block |> Map.to_list()
      Map.merge(form, action_value(action_id, action))
    end)
  end

  defp action_value(action_id, action), do: %{action_id => form_value(action)}

  defp form_value(%{"selected_conversation" => value}), do: value
  defp form_value(%{"selected_option" => %{"value" => value}}), do: value

  defp form_value(%{"selected_options" => options}) do
    Enum.map(options, fn %{"value" => value} -> value end)
  end

  defp form_value(%{"value" => value}), do: value
end
