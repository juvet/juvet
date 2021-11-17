defmodule Juvet.Router.PlatformFactoryTest do
  use ExUnit.Case, async: true

  describe "Juvet.Router.PlatformFactory.new/1" do
    test "returns a SlackPlatform when the platform is slack" do
      assert Juvet.Router.SlackPlatform ==
               Juvet.Router.PlatformFactory.new(:slack)
    end

    test "returns an UnknownFactory when the platform is not recognized" do
      assert Juvet.Router.UnknownPlatform ==
               Juvet.Router.PlatformFactory.new(:blah)
    end
  end

  describe "Juvet.Router.PlatformFactory.validate_route/3" do
    setup do
      route = Juvet.Router.Route.new(:command, "/test", to: "controller#action")

      [platform: Juvet.Router.SlackPlatform, route: route]
    end

    test "delegates to the platform module", %{platform: platform, route: route} do
      assert {:ok, route} ==
               Juvet.Router.PlatformFactory.validate_route(platform, route)
    end

    test "returns an error if the route is not valid", %{platform: platform} do
      error_route = %Juvet.Router.Route{type: :blah}

      assert {:error, {:routing_error, _}} =
               Juvet.Router.PlatformFactory.validate_route(
                 platform,
                 error_route
               )
    end
  end
end
