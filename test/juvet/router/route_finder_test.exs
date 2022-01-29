defmodule Juvet.Router.RouteFinderTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, Request, Route, RouteFinder}

  describe "find/2" do
    setup do
      route = Route.new(:command, "/test", to: "controller#action")

      {:ok, platform} =
        Platform.new(:slack)
        |> Platform.put_route(route)

      request = Request.new(%{params: %{"command" => "test"}})
      request = %{request | platform: :slack, verified?: true}

      [platforms: [platform], request: request]
    end

    test "returns an ok tuple with the route if it was found", %{
      platforms: platforms,
      request: request
    } do
      assert {:ok, route} = RouteFinder.find(platforms, request)
      assert route.type == :command
      assert route.route == "/test"
      assert route.options == [to: "controller#action"]
    end

    test "returns an error tuple with an error if the route was not found", %{
      platforms: platforms,
      request: request
    } do
      request = %{
        request
        | params: Map.merge(request.params, %{"command" => "blah"})
      }

      assert {:error, :not_found} = RouteFinder.find(platforms, request)
    end
  end
end
