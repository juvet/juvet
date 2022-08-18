# Juvet.Router.SlackRouter
# @behavior Juvet.Router.PlatformRouter
defmodule Juvet.Router.SlackPlatform do
  @moduledoc """
  Struct that represents the `Juvet.Router.Route`s that are available for the
  Slack platform.
  """

  # name instead? to remove the platform.name
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

  def find_route(
        %Juvet.Router.Route{type: :view_submission, route: callback_id} = route,
        request
      ) do
    if view_submission_request?(request, callback_id), do: route
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

  defp action_from_payload(%{"actions" => actions}), do: List.first(actions)
  defp action_from_payload(_payload), do: %{}

  defp action_request?(%{params: %{"payload" => payload}}, action_id) do
    action = payload |> Poison.decode!() |> action_from_payload

    normalized_value(action["action_id"]) == normalized_value(action_id)
  end

  defp action_request?(_request, _action_id), do: false

  defp callback_id_from_payload(%{"view" => %{"callback_id" => callback_id}}), do: callback_id
  defp callback_id_from_payload(_payload), do: nil

  defp command_request?(%{params: params}, command) do
    normalized_command(params["command"]) == normalized_command(command)
  end

  defp command_without_slash(command), do: String.trim_leading(command, "/")

  defp normalized_command(nil), do: nil

  defp normalized_command(command), do: normalized_value(command) |> command_without_slash()

  defp normalized_value(nil), do: nil

  defp normalized_value(value), do: value |> String.trim() |> String.downcase()

  defp view_submission_request?(%{params: %{"payload" => payload}}, callback_id) do
    incoming_callback_id = payload |> Poison.decode!() |> callback_id_from_payload

    normalized_value(incoming_callback_id) == normalized_value(callback_id)
  end

  defp view_submission_request?(_request, _callback_id), do: false
end
