defmodule Juvet.Router.RouterFactoryTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, Request, Route, RouterFactory, SlackRouter, UnknownRouter}

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
        | raw_params: Map.merge(request.raw_params, %{"command" => "/blah"})
      }

      assert {:error, error} = RouterFactory.find_route(platform, request)

      assert error ==
               {:unknown_route,
                [
                  router: %SlackRouter{platform: platform},
                  request: request
                ]}
    end
  end

  describe "get_default_routes/1" do
    setup do
      platform = Platform.new(:slack)

      [platform: platform]
    end

    test "returns an ok tuple with the default routes", %{platform: platform} do
      assert {:ok, [route]} = RouterFactory.get_default_routes(platform)
      assert route.type == :url_verification
    end

    test "returns an error if the platform is not valid" do
      unknown_platform = Platform.new(:blah)

      assert {:error, :unknown_platform} = RouterFactory.get_default_routes(unknown_platform)
    end
  end

  describe "router/1" do
    test "returns a module based on the platform" do
      platform = Platform.new(:slack)

      assert SlackRouter == RouterFactory.router(platform)
    end

    test "returns a module based on the platform as an atom" do
      assert SlackRouter == RouterFactory.router(:slack)
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
      assert {:ok, _route} = RouterFactory.validate_route(platform, route)
    end

    test "returns an ok tuple with the route when the action route is valid to add", %{
      platform: platform
    } do
      route = Route.new(:action, "test_action", to: "controller#action")
      assert {:ok, _route} = RouterFactory.validate_route(platform, route)
    end

    test "returns an ok tuple with the route when the view submission route is valid to add", %{
      platform: platform
    } do
      route = Route.new(:view_submission, "test_callback", to: "controller#action")
      assert {:ok, _route} = RouterFactory.validate_route(platform, route)
    end

    test "returns an error tuple with the route when the route is not valid", %{
      platform: platform
    } do
      error_route = %Route{type: :blah}

      assert {:error,
              {:unknown_route,
               [
                 router: %SlackRouter{platform: %Platform{platform: :slack}},
                 route: error_route,
                 opts: []
               ]}} ==
               RouterFactory.validate_route(platform, error_route)
    end

    test "returns an error if the platform is not valid", %{route: route} do
      unknown_platform = Platform.new(:blah)

      assert {:error,
              {:unknown_platform,
               [router: %UnknownRouter{platform: ^unknown_platform}, route: ^route, opts: []]}} =
               RouterFactory.validate_route(
                 unknown_platform,
                 route
               )
    end
  end
end
