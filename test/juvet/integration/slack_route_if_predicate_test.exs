defmodule Juvet.Integration.SlackRouteIfPredicateTest do
  @moduledoc """
  Regression test for the route-level `:if` predicate.

  The unit tests in `Juvet.Router.SlackRouterTest` build routes directly
  via `Route.new/3`, which bypasses the macro / `__before_compile__`
  path that escapes routes for module storage. This test exercises the
  macro path end-to-end — defining a router with `use Juvet.Router` and
  `action(..., if: &Mod.fun/1)` — so that we catch any future change
  that breaks `Macro.escape`-compatibility of the `:if` value.

  `:if` values must be terms `Macro.escape/1` accepts (function captures
  like `&Mod.fun/arity` qualify; inline `fn ... end` closures do not).
  """
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule Matchers do
    def delete?(request), do: action_value_starts_with?(request, "delete:")
    def edit?(request), do: action_value_starts_with?(request, "edit:")

    defp action_value_starts_with?(%{raw_params: %{"payload" => payload}}, prefix) do
      case payload do
        %{"actions" => [%{"value" => value} | _]} -> String.starts_with?(value, prefix)
        _ -> false
      end
    end

    defp action_value_starts_with?(_request, _prefix), do: false
  end

  defmodule MyRouter do
    use Juvet.Router

    alias Juvet.Integration.SlackRouteIfPredicateTest.Matchers

    platform :slack do
      action("recording_action",
        to: "juvet.integration.slack_route_if_predicate_test.test#delete",
        if: &Matchers.delete?/1
      )

      action("recording_action",
        to: "juvet.integration.slack_route_if_predicate_test.test#edit",
        if: &Matchers.edit?/1
      )
    end
  end

  defmodule TestController do
    def delete(%{pid: pid} = context) do
      send(pid, :delete_dispatched)
      {:ok, context}
    end

    def edit(%{pid: pid} = context) do
      send(pid, :edit_dispatched)
      {:ok, context}
    end
  end

  defp fixture(value) do
    payload =
      %{
        "type" => "block_actions",
        "actions" => [%{"action_id" => "recording_action", "value" => value}]
      }
      |> Poison.encode!()

    %{"token" => "SLACK_TOKEN", "payload" => payload}
  end

  describe "with two same-action_id routes gated by :if predicates" do
    setup do
      [signing_secret: generate_slack_signing_secret()]
    end

    test "dispatches to the delete handler when the value matches",
         %{signing_secret: signing_secret} do
      params = fixture("delete:poll:42:1")

      conn =
        request!(
          :post,
          "/slack/actions",
          params,
          slack_headers(params, signing_secret),
          context: %{pid: self()},
          configuration: [
            router: MyRouter,
            slack: [signing_secret: signing_secret]
          ]
        )

      assert conn.status == 200
      assert conn.halted
      assert_received :delete_dispatched
      refute_received :edit_dispatched
    end

    test "dispatches to the edit handler when the value matches",
         %{signing_secret: signing_secret} do
      params = fixture("edit:poll:42:1")

      conn =
        request!(
          :post,
          "/slack/actions",
          params,
          slack_headers(params, signing_secret),
          context: %{pid: self()},
          configuration: [
            router: MyRouter,
            slack: [signing_secret: signing_secret]
          ]
        )

      assert conn.status == 200
      assert conn.halted
      assert_received :edit_dispatched
      refute_received :delete_dispatched
    end
  end
end
