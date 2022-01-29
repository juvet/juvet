defmodule Juvet.Middleware.ActionGenerator do
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
