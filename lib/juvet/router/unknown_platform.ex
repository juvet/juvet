defmodule Juvet.Router.UnknownPlatform do
  def validate_route(route, options \\ %{}),
    do: {:error, {:routing_error, [route: route, options: options]}}
end
