defmodule Juvet.RouterTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Request, RouteError}

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      action("test_action_id", to: "controller#action")
      command("/test", to: "controller#action")
      view_submission("test_callback_id", to: "controller#action")
    end
  end

  describe "compile time validations" do
    test "invalid platform raises RouteError" do
      assert_raise RouteError,
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

      assert Enum.count(List.first(platforms).routes) == 3
      assert Enum.at(List.first(platforms).routes, 0).route == "test_action_id"
      assert Enum.at(List.first(platforms).routes, 1).route == "/test"
      assert Enum.at(List.first(platforms).routes, 2).route == "test_callback_id"
    end
  end

  describe "find_route/2" do
    test "returns an ok tuple with the route if it was found" do
      request = Request.new(%{params: %{"command" => "/test"}})
      request = %{request | platform: :slack, verified?: true}

      assert {:ok, route} = Juvet.Router.find_route(MyRouter, request)
      assert route.options == [to: "controller#action"]
    end

    test "returns an error tuple if it was not found" do
      request = Request.new(%{params: %{"command" => "/blah"}})
      request = %{request | platform: :slack, verified?: true}

      assert {:error, :not_found} = Juvet.Router.find_route(MyRouter, request)
    end
  end
end
