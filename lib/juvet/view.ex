defmodule Juvet.View do
  @moduledoc """
  Represents a single message that is compiled into Elixir code and is sent to different platform
  endpoints using `Template`s.
  """

  defmacro __using__(_opts) do
    quote do
      unquote(prelude())
    end
  end

  defp prelude do
    quote do
      import unquote(__MODULE__)

      use Juvet.SlackView
    end
  end

  def default_view(template, opts \\ []) do
    prefix = Keyword.get(opts, :prefix)

    template
    |> to_string()
    |> String.replace_trailing("_view", "")
    |> Kernel.<>("_view")
    |> Macro.camelize()
    |> maybe_prepend_prefix(prefix)
  end

  defp ensure_view_namespaced!(view) do
    view
    |> to_string()
    |> String.replace_leading("Elixir.", "")
    |> String.replace_prefix("", "Elixir.")
    |> String.to_existing_atom()
  end

  defp maybe_prepend_prefix(suffix, nil), do: suffix
  defp maybe_prepend_prefix(suffix, prefix), do: prefix <> suffix

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
    view = view |> ensure_view_namespaced!() |> Code.ensure_loaded!()

    template_function = String.to_atom("send_#{template}_message")
    platform_template_function = String.to_atom("send_#{platform}_#{template}_message")

    cond do
      function_exported?(view, platform_template_function, 1) ->
        [view, platform_template_function, [assigns]]

      function_exported?(view, template_function, 2) ->
        [view, template_function, [platform, assigns]]

      function_exported?(view, :send_message, 3) ->
        [view, :send_message, [platform, template, assigns]]

      true ->
        raise ArgumentError, message: no_template_message(platform, view, template)
    end
  end

  defp no_template_message(platform, view, template),
    do: "No \"#{platform}\" platform with \"#{template}\" template defined for #{inspect(view)}"
end
