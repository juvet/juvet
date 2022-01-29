defmodule Juvet.Router.SlackPlatformTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.{Platform, Request, Route, SlackPlatform}

  describe "find_route/2" do
    setup do
      route = Route.new(:command, "/test", to: "controller#action")

      {:ok, platform} =
        Platform.new(:slack)
        |> Platform.put_route(route)

      platform = SlackPlatform.new(platform)

      request = Request.new(%{params: %{"command" => "test"}})
      request = %{request | platform: :slack, verified?: true}

      [platform: platform, request: request]
    end

    test "returns an ok tuple with the route if the request is a verified Slack command request",
         %{platform: platform, request: request} do
      assert {:ok, route} = SlackPlatform.find_route(platform, request)
      assert route.type == :command
      assert route.route == "/test"
      assert route.options == [to: "controller#action"]
    end

    test "returns an error tuple with an unverified request", %{
      platform: platform,
      request: request
    } do
      request = %{request | verified?: false}

      assert {:error, {:unverified_route, [platform: platform, request: request]}} =
               SlackPlatform.find_route(platform, request)
    end

    test "returns an error tuple if the request is not found", %{
      platform: platform,
      request: request
    } do
      request = %{
        request
        | params: Map.merge(request.params, %{"command" => "/blah"})
      }

      assert {:error, {:unknown_route, [platform: platform, request: request]}} =
               SlackPlatform.find_route(platform, request)
    end
  end
end
