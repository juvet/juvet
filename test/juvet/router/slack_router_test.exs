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

  describe "find_route/2 with a :text option on a command" do
    defp command_router(routes) do
      {:ok, platform} =
        Enum.reduce(routes, {:ok, Platform.new(:slack)}, fn route, {:ok, acc} ->
          Platform.put_route(acc, route)
        end)

      SlackRouter.new(platform)
    end

    defp command_request(params) do
      request = Request.new(%{params: Map.merge(%{"command" => "/super"}, params)})
      %{request | platform: :slack, verified?: true}
    end

    defp routed_to(routes, params) do
      case SlackRouter.find_route(command_router(routes), command_request(params)) do
        {:ok, route} -> route.options[:to]
        {:error, _} -> nil
      end
    end

    test "matches any text when :text is not given" do
      routes = [Route.new(:command, "/super", to: "any")]

      assert routed_to(routes, %{"text" => "whatever you like"}) == "any"
      assert routed_to(routes, %{}) == "any"
    end

    test "a string matches the first word of the text, ignoring case and spacing" do
      routes = [Route.new(:command, "/super", text: "billing", to: "billing")]

      assert routed_to(routes, %{"text" => "billing"}) == "billing"
      assert routed_to(routes, %{"text" => "  Billing now please"}) == "billing"
      refute routed_to(routes, %{"text" => "broadcast"})
      refute routed_to(routes, %{"text" => "billings"})
      refute routed_to(routes, %{})
    end

    # Before :text was honored the first route for a command caught every
    # subcommand, so routes had to be ordered and guarded with :if.
    test "picks the route whose text matches, whatever order they were defined in" do
      routes = [
        Route.new(:command, "/super", text: "billing", to: "billing"),
        Route.new(:command, "/super", text: "broadcast", to: "broadcast")
      ]

      assert routed_to(routes, %{"text" => "broadcast"}) == "broadcast"
      assert routed_to(routes, %{"text" => "billing"}) == "billing"
      refute routed_to(routes, %{"text" => "help"})
    end

    test "a list matches when the first word is any of them" do
      routes = [Route.new(:command, "/super", text: ["list", "show"], to: "list")]

      assert routed_to(routes, %{"text" => "show sent"}) == "list"
      assert routed_to(routes, %{"text" => "list"}) == "list"
      refute routed_to(routes, %{"text" => "billing"})
    end

    test "a regex matches against the whole trimmed text" do
      routes = [Route.new(:command, "/super", text: ~r/^$/, to: "bare")]

      assert routed_to(routes, %{"text" => ""}) == "bare"
      assert routed_to(routes, %{"text" => "   "}) == "bare"
      assert routed_to(routes, %{}) == "bare"
      refute routed_to(routes, %{"text" => "list"})
    end

    test "requires :text and :if to both match" do
      routes = [
        Route.new(:command, "/super",
          text: "billing",
          if: fn %{raw_params: params} -> params["user_id"] == "U1" end,
          to: "billing"
        )
      ]

      assert routed_to(routes, %{"text" => "billing", "user_id" => "U1"}) == "billing"
      refute routed_to(routes, %{"text" => "billing", "user_id" => "U2"})
      refute routed_to(routes, %{"text" => "broadcast", "user_id" => "U1"})
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
