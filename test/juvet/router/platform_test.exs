defmodule Juvet.Router.PlatformTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, Request, Route, SlackPlatform}

  describe "put_route/3" do
    setup do
      platform = Platform.new(:slack)
      route = Route.new(:command, "/test", to: "controller#action")

      [platform: platform, route: route]
    end

    test "returns an ok tuple with the route added to the returning platform",
         %{platform: platform, route: route} do
      assert {:ok, platform} = Platform.put_route(platform, route)
      assert Enum.count(platform.routes) == 1
      assert List.first(platform.routes).type == :command
    end

    test "returns an error tuple with the error from the returning platform", %{
      platform: platform
    } do
      error_route = %Route{type: :blah}

      assert {:error, error} = Platform.put_route(platform, error_route)

      assert error ==
               {:unknown_route,
                [
                  platform: %SlackPlatform{platform: platform},
                  route: error_route,
                  options: %{}
                ]}
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
      assert {:ok, route} = Platform.find_route(platform, request)
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

      assert {:error, error} = Platform.find_route(platform, request)

      assert error ==
               {:unknown_route,
                [
                  platform: %SlackPlatform{platform: platform},
                  request: request
                ]}
    end
  end

  describe "validate/1" do
    test "returns an ok tuple with the platform" do
      platform = Platform.new(:slack)

      assert {:ok, actual} = Platform.validate(platform)
      assert actual == platform
    end

    test "returns an error tuple if the platform is not valid" do
      platform = Platform.new(:blah)

      assert {:error, :unknown_platform} = Platform.validate(platform)
    end
  end

  describe "validate_route/3" do
    setup do
      platform = Platform.new(:slack)

      [platform: platform]
    end

    test "returns an ok tuple with the route when the command route is valid to add", %{
      platform: platform
    } do
      route = Route.new(:command, "/test", to: "controller#action")
      assert {:ok, route} = Platform.validate_route(platform, route)
    end

    test "returns an ok tuple with the route when the action route is valid to add", %{
      platform: platform
    } do
      route = Route.new(:action, "test_action", to: "controller#action")
      assert {:ok, route} = Platform.validate_route(platform, route)
    end

    test "returns an ok tuple with the route when the view submission route is valid to add", %{
      platform: platform
    } do
      route = Route.new(:view_submission, "test_callback", to: "controller#action")
      assert {:ok, route} = Platform.validate_route(platform, route)
    end

    test "returns an error tuple with the route when the route is not valid", %{
      platform: platform
    } do
      error_route = %Route{type: :blah}

      assert {:error,
              {:unknown_route,
               [
                 platform: %SlackPlatform{platform: platform},
                 route: error_route,
                 options: %{}
               ]}} ==
               Platform.validate_route(platform, error_route)
    end
  end
end
