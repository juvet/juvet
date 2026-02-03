defmodule Juvet.Template.Compiler.Slack.Elements.Overflow do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Option
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :overflow, attributes: attrs} = el) do
    %{type: "overflow"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> put_options(el)
  end

  defp put_options(map, %{children: %{options: options}}) when is_list(options),
    do: Map.put(map, :options, Enum.map(options, &Option.compile/1))

  defp put_options(map, _), do: map
end
