defmodule Juvet.Router.RouterFactoryTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, RouterFactory, Request, Route, SlackRouter, UnknownRouter}

  describe "find_route/2" do
    setup do
      platform = Platform.new(:slack)
      route = Route.new(:command, "/test", to: "controller#action")
      {:ok, platform} = Platform.put_route(platform, route)

      request = Request.new(%{params: %{"command" => "test"}})
      request = %{request | platform: :slack, verified?: true}

      [platform: platform, request: request]
    end

    test "returns an ok tuple with the route that were found", %{
      platform: platform,
      request: request
    } do
      assert {:ok, route} = RouterFactory.find_route(platform, request)
      assert route.type == :command
      assert route.route == "/test"
      assert route.options == [to: "controller#action"]
    end

    test "returns an error tuple with the route when the route is not found", %{
      platform: platform,
      request: request
    } do
      request = %{
        request
        | params: Map.merge(request.params, %{"command" => "/blah"})
      }

      assert {:error, error} = RouterFactory.find_route(platform, request)

      assert error ==
               {:unknown_route,
                [
                  platform: %SlackRouter{platform: platform},
                  request: request
                ]}
    end
  end

  describe "validate_route/3" do
    setup do
      route = Route.new(:command, "/test", to: "controller#action")
      platform = Platform.new(:slack)

      [platform: platform, route: route]
    end

    test "returns an ok tuple with the route when the command route is valid to add", %{
      platform: platform
    } do
      route = Route.new(:command, "/test", to: "controller#action")
      assert {:ok, route} = RouterFactory.validate_route(platform, route)
    end

    test "returns an ok tuple with the route when the action route is valid to add", %{
      platform: platform
    } do
      route = Route.new(:action, "test_action", to: "controller#action")
      assert {:ok, route} = RouterFactory.validate_route(platform, route)
    end

    test "returns an ok tuple with the route when the view submission route is valid to add", %{
      platform: platform
    } do
      route = Route.new(:view_submission, "test_callback", to: "controller#action")
      assert {:ok, route} = RouterFactory.validate_route(platform, route)
    end

    test "returns an error tuple with the route when the route is not valid", %{
      platform: platform
    } do
      error_route = %Route{type: :blah}

      assert {:error,
              {:unknown_route,
               [
                 platform: %SlackRouter{platform: %Platform{platform: :slack}},
                 route: error_route,
                 options: %{}
               ]}} ==
               RouterFactory.validate_route(platform, error_route)
    end

    test "returns an error if the platform is not valid", %{route: route} do
      unknown_platform = Platform.new(:blah)

      assert {:error,
              {:unknown_platform,
               [router: %UnknownRouter{platform: unknown_platform}, route: route, options: %{}]}} =
               RouterFactory.validate_route(
                 unknown_platform,
                 route
               )
    end
  end
end
