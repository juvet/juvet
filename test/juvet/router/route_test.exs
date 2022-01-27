defmodule Juvet.Router.RouteTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.Route

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
