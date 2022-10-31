defmodule Juvet.Router.SlackRouterTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, Request, Route, SlackRouter}

  describe "find_route/2" do
    setup do
      route = Route.new(:command, "/test", to: "controller#action")

      {:ok, platform} =
        Platform.new(:slack)
        |> Platform.put_route(route)

      router = SlackRouter.new(platform)

      request = Request.new(%{params: %{"command" => "test"}})
      request = %{request | platform: :slack, verified?: true}

      [router: router, request: request]
    end

    test "returns an ok tuple with the route if the request is a verified Slack command request",
         %{router: router, request: request} do
      assert {:ok, route} = SlackRouter.find_route(router, request)
      assert route.type == :command
      assert route.route == "/test"
      assert route.options == [to: "controller#action"]
    end

    test "returns an error tuple with an unverified request", %{
      router: router,
      request: request
    } do
      request = %{request | verified?: false}

      assert {:error, {:unverified_route, [router: ^router, request: ^request]}} =
               SlackRouter.find_route(router, request)
    end

    test "returns an error tuple if the request is not found", %{
      router: router,
      request: request
    } do
      request = %{
        request
        | params: Map.merge(request.params, %{"command" => "/blah"})
      }

      assert {:error, {:unknown_route, [router: ^router, request: ^request]}} =
               SlackRouter.find_route(router, request)
    end
  end
end
