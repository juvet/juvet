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

      assert {:error, {:unverified_route, [router: ^router, request: ^request, opts: []]}} =
               SlackRouter.find_route(router, request)
    end

    test "returns an error tuple if the request is not found", %{
      router: router,
      request: request
    } do
      request = %{
        request
        | raw_params: Map.merge(request.raw_params, %{"command" => "/blah"})
      }

      assert {:error, {:unknown_route, [router: ^router, request: ^request, opts: []]}} =
               SlackRouter.find_route(router, request)
    end
  end

  describe "find_route/2 with :if predicate" do
    setup do
      payload = %{
        "type" => "block_actions",
        "actions" => [%{"action_id" => "recording_action", "value" => "delete:poll:42:1"}]
      }

      request = Request.new(%{params: %{"payload" => payload}})

      request = %{
        request
        | platform: :slack,
          verified?: true,
          raw_params: %{"payload" => payload}
      }

      [request: request]
    end

    defp router_with(routes) do
      {:ok, platform} =
        Enum.reduce(routes, {:ok, Platform.new(:slack)}, fn route, {:ok, acc} ->
          Platform.put_route(acc, route)
        end)

      SlackRouter.new(platform)
    end

    defp action_value_starts_with?(prefix) do
      fn %{raw_params: %{"payload" => payload}} ->
        %{"actions" => [%{"value" => value} | _]} = payload
        String.starts_with?(value, prefix)
      end
    end

    test "matches when the :if predicate returns true", %{request: request} do
      route =
        Route.new(:action, "recording_action",
          to: "controller#delete",
          if: action_value_starts_with?("delete:")
        )

      router = router_with([route])

      assert {:ok, matched} = SlackRouter.find_route(router, request)
      assert matched.options[:to] == "controller#delete"
    end

    test "does not match when the :if predicate returns false", %{request: request} do
      route =
        Route.new(:action, "recording_action",
          to: "controller#edit",
          if: action_value_starts_with?("edit:")
        )

      router = router_with([route])

      assert {:error, {:unknown_route, _}} = SlackRouter.find_route(router, request)
    end

    test "falls through to the next route when an earlier :if fails", %{request: request} do
      edit_route =
        Route.new(:action, "recording_action",
          to: "controller#edit",
          if: action_value_starts_with?("edit:")
        )

      delete_route =
        Route.new(:action, "recording_action",
          to: "controller#delete",
          if: action_value_starts_with?("delete:")
        )

      router = router_with([edit_route, delete_route])

      assert {:ok, matched} = SlackRouter.find_route(router, request)
      assert matched.options[:to] == "controller#delete"
    end

    test "routes without :if are unaffected", %{request: request} do
      route = Route.new(:action, "recording_action", to: "controller#any")
      router = router_with([route])

      assert {:ok, matched} = SlackRouter.find_route(router, request)
      assert matched.options[:to] == "controller#any"
    end
  end

  describe "request_format/1" do
    test "returns :message when the payload has a message request" do
      payload = %{
        "message" => %{"ts" => "1234567890.123456"},
        "response_url" => "https://example.com"
      }

      request = %Request{platform: :slack, raw_params: %{"payload" => payload}}

      assert SlackRouter.request_format(request) == {:ok, :message}
    end

    test "returns :modal when the payload has a modal request" do
      payload = %{
        "container" => %{"type" => "view"},
        "view" => %{"id" => "V12345"}
      }

      request = %Request{platform: :slack, raw_params: %{"payload" => payload}}

      assert SlackRouter.request_format(request) == {:ok, :modal}
    end

    test "returns :page when the params has a home tab request" do
      raw_params = %{
        "event" => %{"type" => "app_home_opened", "view" => %{"id" => "V12345"}}
      }

      request = %Request{platform: :slack, raw_params: raw_params}

      assert SlackRouter.request_format(request) == {:ok, :page}
    end

    test "returns :none when the params has any other event request" do
      raw_params = %{
        "event" => %{"type" => "channel_rename", "channel" => %{"id" => "C12345"}}
      }

      request = %Request{platform: :slack, raw_params: raw_params}

      assert SlackRouter.request_format(request) == {:ok, :none}
    end
  end
end
