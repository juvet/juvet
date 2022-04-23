defmodule Juvet.Router.SlackPlatform do
  @moduledoc """
  Struct that represents the `Juvet.Router.Route`s that are available for the
  Slack platform.
  """

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
        %Juvet.Router.Route{type: :action, route: action_id} = route,
        request
      ) do
    if action_request?(request, action_id), do: route
  end

  def find_route(
        %Juvet.Router.Route{type: :command, route: command_text} = route,
        request
      ) do
    if command_request?(request, command_text), do: route
  end

  def validate(%{platform: %{platform: :slack} = platform}), do: {:ok, platform}
  def validate(_platform), do: {:error, :unknown_platform}

  def validate_route(
        _platform,
        %Juvet.Router.Route{type: :action} = route,
        _options
      ),
      do: {:ok, route}

  def validate_route(
        _platform,
        %Juvet.Router.Route{type: :command} = route,
        _options
      ),
      do: {:ok, route}

  def validate_route(
        _platform,
        %Juvet.Router.Route{type: :view_submission} = route,
        _options
      ),
      do: {:ok, route}

  def validate_route(platform, %Juvet.Router.Route{} = route, options),
    do: {:error, {:unknown_route, [platform: platform, route: route, options: options]}}

  defp action_request?(%{params: %{"payload" => payload}}, action_id) do
    payload = payload |> Poison.decode!()
    action = payload["actions"] |> List.first()

    action["action_id"] == action_id
  end

  defp action_request?(_request, _action_id), do: false

  defp command_request?(%{params: params}, command) do
    normalized_command(params["command"]) == normalized_command(command)
  end

  defp command_without_slash(command), do: String.trim_leading(command, "/")

  defp normalized_command(nil), do: nil

  defp normalized_command(command) do
    command |> String.trim() |> String.downcase() |> command_without_slash()
  end
end
