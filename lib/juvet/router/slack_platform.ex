defmodule Juvet.Router.SlackPlatform do
  def validate_route(
        _platform,
        %Juvet.Router.Route{type: :command} = route,
        _options
      ),
      do: {:ok, route}

  def validate_route(_platform, %Juvet.Router.Route{} = route, options),
    do: {:error, {:unknown_route, [route: route, options: options]}}
end
