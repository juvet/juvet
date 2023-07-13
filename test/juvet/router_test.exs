defmodule Juvet.RouterTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Middleware, Request, RouteError}

  defmodule MoreMiddleware do
    def call(context), do: {:ok, context}
  end

  defmodule MyMiddleware do
    def call(context), do: {:ok, context}
  end

  defmodule MyRouter do
    use Juvet.Router

    middleware do
      include(MyMiddleware)
      include(MoreMiddleware)
    end

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

  describe "middlewares/1" do
    test "accumulates all the system middleware and router middleware that can run" do
      middleware = Juvet.Router.middlewares(MyRouter)

      assert Enum.count(middleware) == 11

      assert Enum.map(middleware, & &1.module) == [
               Juvet.Middleware.ParseRequest,
               Juvet.Middleware.IdentifyRequest,
               Juvet.Middleware.Slack.VerifyRequest,
               Juvet.Middleware.DecodeRequestParams,
               Juvet.Middleware.NormalizeRequestParams,
               Juvet.Middleware.RouteRequest,
               Juvet.Middleware.BuildDefaultResponse,
               Juvet.RouterTest.MyMiddleware,
               Juvet.RouterTest.MoreMiddleware,
               Juvet.Middleware.ActionGenerator,
               Juvet.Middleware.ActionRunner
             ]
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

      assert Enum.count(List.first(platforms).routes) == 5
      refute Enum.at(List.first(platforms).routes, 0).route
      assert Enum.at(List.first(platforms).routes, 1).route == :callback
      assert Enum.at(List.first(platforms).routes, 2).route == "test_action_id"
      assert Enum.at(List.first(platforms).routes, 3).route == "/test"
      assert Enum.at(List.first(platforms).routes, 4).route == "test_callback_id"
    end
  end

  describe "find_middleware/2" do
    setup do
      [middlewares: Juvet.Router.middlewares(MyRouter)]
    end

    test "returns an ok tuple with a list of middleware if they were found", %{
      middlewares: middlewares
    } do
      assert {:ok, middleware} = Juvet.Router.find_middleware(middlewares)
      assert Enum.count(middleware) == 11
    end

    test "returns an ok tuple with a list of partial middleware", %{middlewares: middlewares} do
      assert {:ok, middleware} = Juvet.Router.find_middleware(middlewares, partial: true)
      assert Enum.count(middleware) == 4
    end

    test "returns an error tuple if none were found" do
      assert {:error, :no_middleware} =
               Juvet.Router.find_middleware(
                 [Middleware.new(Juvet.Middleware.ParseRequest, partial: false)],
                 partial: true
               )
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
