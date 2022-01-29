defmodule Juvet.Middleware.ActionGenerator do
  @moduledoc """
  Middleware to convert a path (e.g. `"test#action"`) to a controller module and function (e.g. `TestController.action()`).
  """
  def call(%{path: path} = context) do
    {:ok, Map.put_new(context, :action, generate_action(path))}
  end

  def call(_context), do: {:error, "`path` missing in the `context`"}

  defp generate_action(path) do
    [controller_prefix, action_name] = String.split(path, "#", parts: 2, trim: true)

    controller_name =
      String.split("elixir.#{controller_prefix}_controller", ".")
      |> Enum.map_join(".", fn part -> Macro.camelize(part) end)

    {String.to_atom(controller_name), String.to_atom(action_name)}
  end
end
