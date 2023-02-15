defmodule Juvet.View do
  @moduledoc """
  Represents a single message that is compiled into Elixir code and is sent to different platform
  endpoints using `Template`s.
  """

  def send_message(view, template, assigns),
    do:
      assigns
      |> get_platform()
      |> send_message_via(view, template, assigns)

  def send_message_via(platform, view, template, assigns) do
    case get_mfa(platform, view, template, assigns) do
      [module, function, args] ->
        try do
          apply(module, function, args)
        catch
          _, _ -> raise ArgumentError, message: no_template_message(platform, view, template)
        end

      _ ->
        raise ArgumentError, message: no_template_message(platform, view, template)
    end
  end

  defp get_platform(%{request: %{platform: platform}}), do: platform
  defp get_platform(_assigns), do: :unknown

  defp get_mfa(platform, view, template, assigns) do
    template_function = String.to_atom("send_#{template}_message")
    platform_template_function = String.to_atom("send_#{platform}_#{template}_message")

    cond do
      function_exported?(view, platform_template_function, 1) ->
        [view, platform_template_function, [assigns]]

      function_exported?(view, template_function, 2) ->
        [view, template_function, [platform, assigns]]

      function_exported?(view, :send_message, 3) ->
        [view, :send_message, [platform, template, assigns]]
    end
  end

  defp no_template_message(platform, view, template),
    do: "No \"#{platform}\" platform with \"#{template}\" template defined for #{inspect(view)}"
end
