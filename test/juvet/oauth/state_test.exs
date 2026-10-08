defmodule Juvet.OAuth.StateTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  alias Juvet.ConfigurationError
  alias Juvet.OAuth.State

  @configuration [
    slack: [oauth_callback_endpoint: "/auth/slack/callback", state_secret: "STATE_SECRET"]
  ]

  @secret_key_base String.duplicate("a", 64)

  describe "put/2" do
    test "returns the state and sets it in a signed cookie scoped to the callback" do
      assert {:ok, conn, state} = State.put(conn(:get, "/auth/slack"), @configuration)

      assert is_binary(state) and byte_size(state) >= 32

      cookie = conn.resp_cookies[State.cookie_name()]
      refute cookie.value == state
      assert cookie.http_only
      assert cookie.same_site == "Lax"
      assert cookie.path == "/auth/slack/callback"
      assert cookie.max_age == 600
    end

    test "generates a different state each time" do
      {:ok, _conn, state1} = State.put(conn(:get, "/auth/slack"), @configuration)
      {:ok, _conn, state2} = State.put(conn(:get, "/auth/slack"), @configuration)

      refute state1 == state2
    end

    test "marks the cookie secure over https" do
      conn = %{conn(:get, "/auth/slack") | scheme: :https}

      assert {:ok, conn, _state} = State.put(conn, @configuration)
      assert conn.resp_cookies[State.cookie_name()].secure
    end

    test "returns a configuration error without a state secret" do
      assert {:error, %ConfigurationError{}} =
               State.put(conn(:get, "/auth/slack"), slack: [client_id: "CLIENT_ID"])
    end

    test "falls back to the conn's secret_key_base without a state secret" do
      conn = %{conn(:get, "/auth/slack") | secret_key_base: @secret_key_base}

      assert {:ok, conn, state} = State.put(conn, slack: [])

      cookie = conn.resp_cookies[State.cookie_name()].value

      assert :ok =
               State.verify(
                 %{callback_conn(cookie) | secret_key_base: @secret_key_base},
                 %{"state" => state},
                 slack: []
               )
    end
  end

  describe "verify/3" do
    setup do
      {:ok, conn, state} = State.put(conn(:get, "/auth/slack"), @configuration)

      [cookie: conn.resp_cookies[State.cookie_name()].value, state: state]
    end

    test "is ok when the state matches the cookie", %{cookie: cookie, state: state} do
      assert :ok = State.verify(callback_conn(cookie), %{"state" => state}, @configuration)
    end

    test "is invalid when the state does not match the cookie", %{cookie: cookie} do
      assert {:error, :invalid_state} =
               State.verify(callback_conn(cookie), %{"state" => "FORGED"}, @configuration)
    end

    test "is invalid when the state param is missing", %{cookie: cookie} do
      assert {:error, :invalid_state} = State.verify(callback_conn(cookie), %{}, @configuration)
    end

    test "is invalid when the cookie is missing", %{state: state} do
      assert {:error, :invalid_state} =
               State.verify(
                 conn(:get, "/auth/slack/callback"),
                 %{"state" => state},
                 @configuration
               )
    end

    test "is invalid when the cookie was signed with another secret", %{state: state} do
      other = [slack: [oauth_callback_endpoint: "/auth/slack/callback", state_secret: "OTHER"]]
      {:ok, conn, _} = State.put(conn(:get, "/auth/slack"), other)
      cookie = conn.resp_cookies[State.cookie_name()].value

      assert {:error, :invalid_state} =
               State.verify(callback_conn(cookie), %{"state" => state}, @configuration)
    end

    test "is invalid when the cookie has been tampered with", %{cookie: cookie, state: state} do
      assert {:error, :invalid_state} =
               State.verify(callback_conn(cookie <> "x"), %{"state" => state}, @configuration)
    end

    test "returns a configuration error without a state secret", %{cookie: cookie, state: state} do
      assert {:error, %ConfigurationError{}} =
               State.verify(callback_conn(cookie), %{"state" => state}, slack: [])
    end

    test "prefers the state secret over the conn's secret_key_base", %{
      cookie: cookie,
      state: state
    } do
      conn = %{callback_conn(cookie) | secret_key_base: @secret_key_base}

      assert :ok = State.verify(conn, %{"state" => state}, @configuration)
      assert {:error, :invalid_state} = State.verify(conn, %{"state" => state}, slack: [])
    end
  end

  describe "delete/2" do
    test "expires the cookie on the callback path" do
      conn = State.delete(conn(:get, "/auth/slack/callback"), @configuration)

      cookie = conn.resp_cookies[State.cookie_name()]
      assert cookie.max_age == 0
      assert cookie.path == "/auth/slack/callback"
    end
  end

  defp callback_conn(cookie) do
    conn(:get, "/auth/slack/callback")
    |> put_req_cookie(State.cookie_name(), cookie)
  end
end
