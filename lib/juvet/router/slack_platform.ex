defmodule Juvet.Router.SlackPlatform do
  defstruct platform: nil

  def new(platform) do
    %__MODULE__{platform: platform}
  end

  def find_route(platform, %{verified?: false} = request),
    do: {:error, {:unverified_route, [platform: platform, request: request]}}

  def find_route(
        %{platform: %{routes: routes}} = platform,
        %{platform: :slack, verified?: true} = request
      ) do
    case Enum.find(routes, &(!is_nil(find_route(&1, request)))) do
      nil -> {:error, {:unknown_route, [platform: platform, request: request]}}
      route -> {:ok, route}
    end
  end

  def find_route(
        %Juvet.Router.Route{type: :command, route: command_text} = route,
        request
      ) do
    if command_request?(request, command_without_slash(command_text)), do: route
  end

  def validate_route(
        _platform,
        %Juvet.Router.Route{type: :command} = route,
        _options
      ),
      do: {:ok, route}

  def validate_route(platform, %Juvet.Router.Route{} = route, options),
    do:
      {:error,
       {:unknown_route, [platform: platform, route: route, options: options]}}

  defp command_request?(%{params: params}, command) do
    normalized_command(params["command"]) == normalized_command(command)
  end

  defp command_without_slash(command), do: String.trim_leading(command, "/")

  defp normalized_command(nil), do: nil

  defp normalized_command(command) do
    command |> String.trim() |> String.downcase() |> command_without_slash()
  end
end
