defmodule Juvet.Router.PlatformFactoryTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, PlatformFactory, Request, Route, SlackPlatform, UnknownPlatform}

  describe "new/1" do
    test "returns a SlackPlatform when the platform is slack" do
      platform = Platform.new(:slack)

      assert %SlackPlatform{platform: platform} ==
               PlatformFactory.new(platform)
    end

    test "returns an UnknownFactory when the platform is not recognized" do
      platform = Platform.new(:blah)

      assert %UnknownPlatform{platform: platform} ==
               PlatformFactory.new(platform)
    end
  end

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
      assert {:ok, route} = PlatformFactory.find_route(platform, request)
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

      assert {:error, error} = PlatformFactory.find_route(platform, request)

      assert error ==
               {:unknown_route,
                [
                  platform: %SlackPlatform{platform: platform},
                  request: request
                ]}
    end
  end

  describe "validate_route/3" do
    setup do
      route = Route.new(:command, "/test", to: "controller#action")
      platform = Platform.new(:slack)

      [platform: %SlackPlatform{platform: platform}, route: route]
    end

    test "delegates to the platform module", %{platform: platform, route: route} do
      assert {:ok, route} ==
               PlatformFactory.validate_route(platform, route)
    end

    test "returns an error if the route is not valid", %{platform: platform} do
      error_route = %Route{type: :blah}

      assert {:error, {:unknown_route, [platform: platform, route: error_route, options: %{}]}} =
               PlatformFactory.validate_route(
                 platform,
                 error_route
               )
    end

    test "returns an error if the platform is not valid", %{route: route} do
      unknown_platform = %UnknownPlatform{platform: :blah}

      assert {:error,
              {:unknown_platform, [platform: unknown_platform, route: route, options: %{}]}} =
               PlatformFactory.validate_route(
                 unknown_platform,
                 route
               )
    end
  end
end
