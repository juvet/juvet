defmodule Juvet.Router.PlatformFactoryTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.PlatformFactory

  describe "new/1" do
    test "returns a SlackPlatform when the platform is slack" do
      platform = Juvet.Router.Platform.new(:slack)

      assert %Juvet.Router.SlackPlatform{platform: platform} ==
               PlatformFactory.new(platform)
    end

    test "returns an UnknownFactory when the platform is not recognized" do
      platform = Juvet.Router.Platform.new(:blah)

      assert %Juvet.Router.UnknownPlatform{platform: platform} ==
               PlatformFactory.new(platform)
    end
  end

  describe "validate_route/3" do
    setup do
      route = Juvet.Router.Route.new(:command, "/test", to: "controller#action")
      platform = Juvet.Router.Platform.new(:slack)

      [platform: %Juvet.Router.SlackPlatform{platform: platform}, route: route]
    end

    test "delegates to the platform module", %{platform: platform, route: route} do
      assert {:ok, route} ==
               PlatformFactory.validate_route(platform, route)
    end

    test "returns an error if the route is not valid", %{platform: platform} do
      error_route = %Juvet.Router.Route{type: :blah}

      assert {:error,
              {:unknown_route,
               [platform: platform, route: error_route, options: %{}]}} =
               PlatformFactory.validate_route(
                 platform,
                 error_route
               )
    end

    test "returns an error if the platform is not valid", %{route: route} do
      unknown_platform = %Juvet.Router.UnknownPlatform{platform: :blah}

      assert {:error,
              {:unknown_platform,
               [platform: unknown_platform, route: route, options: %{}]}} =
               PlatformFactory.validate_route(
                 unknown_platform,
                 route
               )
    end
  end
end
