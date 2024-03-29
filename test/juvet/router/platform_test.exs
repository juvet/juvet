defmodule Juvet.Router.PlatformTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, Route, SlackRouter}

  describe "put_default_routes/1" do
    setup do
      platform = Platform.new(:slack)

      [platform: platform]
    end

    test "returns an ok tuple with the default routes added to the returnning platform", %{
      platform: platform
    } do
      assert {:ok, platform} = Platform.put_default_routes(platform)
      assert Enum.count(platform.routes) == 2
      assert List.first(platform.routes).type == :url_verification
      assert List.last(platform.routes).type == :oauth
    end

    test "returns an error tuple if the platform is unknown" do
      assert {:error, _error} = Platform.put_default_routes(Platform.new(:blah))
    end
  end

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
                  opts: []
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
