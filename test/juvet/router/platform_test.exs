defmodule Juvet.Router.PlatformTest do
  use ExUnit.Case, async: true

  describe "Juvet.Router.Platform.validate_route/3" do
    setup do
      platform = Juvet.Router.Platform.new(:slack)
      route = Juvet.Router.Route.new(:command, "/test", to: "controller#action")

      [platform: platform, route: route]
    end

    test "returns an ok tuple with the route when the route is valid to add", %{
      platform: platform,
      route: route
    } do
      assert {:ok, route} =
               Juvet.Router.Platform.validate_route(platform, route)
    end

    test "returns an error tuple with the route when the route is not valid", %{
      platform: platform
    } do
      error_route = %Juvet.Router.Route{type: :blah}

      assert {:error, {:routing_error, [route: error_route, options: %{}]}} ==
               Juvet.Router.Platform.validate_route(platform, error_route)
    end
  end
end
