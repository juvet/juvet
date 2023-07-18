defmodule Juvet.Router.RouteTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.Route

  describe "match?/3" do
    setup do
      route = Route.new(:command, "/test", to: "controller#action")

      [route: route]
    end

    test "returns true if the type and route parts match", %{route: route} do
      assert Route.match?(route, "command", "/test")
    end

    test "returns false if the type does not match", %{route: route} do
      refute Route.match?(route, :action, "/test")
    end

    test "returns false if the route does not match", %{route: route} do
      refute Route.match?(route, "command", "test")
    end
  end

  describe "path/1" do
    test "returns the path from the options" do
      route = Route.new(:command, "/test", to: "controller#action")

      assert Route.path(route) == "controller#action"
    end

    test "returns nil if the option does not exist" do
      route = Route.new(:command, "/test")

      assert is_nil(Route.path(route))
    end
  end
end
