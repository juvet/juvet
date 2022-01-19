defmodule Juvet.RouterTest do
  use ExUnit.Case, async: true

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      command("/test", to: "controller#action")
    end
  end

  describe "compile time validations" do
    test "invalid platform raises RouteError" do
      assert_raise Juvet.Router.RouteError,
                   "Platform `blah` is not valid.",
                   fn ->
                     defmodule MyBadRouter do
                       use Juvet.Router

                       platform(:blah, do: nil)
                     end
                   end
    end
  end

  describe "exists?/1" do
    test "returns true if the router is defined" do
      assert Juvet.Router.exists?(MyRouter)
    end

    test "returns false if the router is defined" do
      refute Juvet.Router.exists?(Blah)
    end
  end

  describe "platform/2" do
    test "accumulates the platforms within the router" do
      platforms = Juvet.Router.platforms(MyRouter)

      assert Enum.count(platforms) == 1
      assert List.first(platforms).platform == :slack
    end

    test "accumulates the routes within the router" do
      platforms = Juvet.Router.platforms(MyRouter)

      assert Enum.count(List.first(platforms).routes) == 1
      assert List.first(List.first(platforms).routes).route == "/test"
    end
  end

  describe "find_route/2" do
    test "returns an ok tuple with the route if it was found" do
      request = Juvet.Router.Request.new(%{params: %{"command" => "test"}})
      request = %{request | platform: :slack, verified?: true}

      assert {:ok, route} = Juvet.Router.find_route(MyRouter, request)
      assert route.options == [to: "controller#action"]
    end

    test "returns an error tuple if it was not found" do
      request = Juvet.Router.Request.new(%{params: %{"command" => "blah"}})
      request = %{request | platform: :slack, verified?: true}

      assert {:error, :not_found} = Juvet.Router.find_route(MyRouter, request)
    end
  end
end
