defmodule Juvet.Router.PlatformTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, Route, SlackRouter}

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
                  router: %SlackRouter{platform: platform},
                  route: error_route,
                  options: %{}
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
end
