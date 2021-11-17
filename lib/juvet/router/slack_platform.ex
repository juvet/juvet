defmodule Juvet.Router.SlackPlatform do
  def validate_route(route, options \\ %{})

  def validate_route(
        %Juvet.Router.Route{type: :command} = route,
        _options
      ),
      do: {:ok, route}

  def validate_route(%Juvet.Router.Route{} = route, options),
    do: {:error, {:routing_error, [route: route, options: options]}}
end
