defmodule Juvet.RunnerTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      command("/test", to: "juvet.runner_test.test#action")
    end
  end

  defmodule TestController do
    def action(%{pid: pid}) do
      send(pid, :called_controller)
    end

    def action(_context) do
    end
  end

  describe "route/2" do
    setup do
      [path: "juvet.runner_test.test#action"]
    end

    test "can merge with the default configuration by adding a configuration option",
         %{path: path} do
      {:ok, context} =
        Juvet.Runner.route(path, %{configuration: [router: MyRouter]})

      assert Keyword.get(context[:configuration], :router) == MyRouter
    end

    test "adds the configuration to the context", %{path: path} do
      {:ok, context} = Juvet.Runner.route(path)

      assert Map.fetch!(context, :configuration) == Juvet.configuration()
    end

    test "adds the current values in the context", %{path: path} do
      {:ok, context} = Juvet.Runner.route(path, %{blah: "bleh"})

      assert Map.fetch!(context, :blah) == "bleh"
    end

    test "adds the path to the context", %{path: path} do
      {:ok, context} = Juvet.Runner.route(path)

      assert Map.fetch!(context, :path) == path
    end

    test "adds the route to the context based on the path", %{path: path} do
      {:ok, context} = Juvet.Runner.route(path)

      assert Map.fetch!(context, :action) ==
               {:"Elixir.Juvet.RunnerTest.TestController", :action}
    end

    test "calls the controller module and action from the path", %{path: path} do
      {:ok, _context} = Juvet.Runner.route(path, %{pid: self()})

      assert_received :called_controller
    end
  end

  describe "run/2" do
    setup do
      params = %{"command" => "test", "team_id" => "T12345"}
      signing_secret = generate_slack_signing_secret()
      config = [router: MyRouter, slack: [signing_secret: signing_secret]]

      conn =
        %Plug.Conn{
          req_headers: slack_headers(params, signing_secret),
          method: "POST",
          params: params,
          request_path: "/slack/commands",
          status: 200
        }
        |> put_raw_body()

      [conn: conn, config: config, params: params]
    end

    test "can merge with the default configuration by adding a configuration option",
         %{conn: conn, config: config} do
      {:ok, context} = Juvet.Runner.run(conn, %{configuration: config})

      assert Keyword.get(context[:configuration], :router) == MyRouter
    end

    test "adds the conn to the context", %{conn: conn, config: config} do
      {:ok, context} = Juvet.Runner.run(conn, %{configuration: config})

      assert Map.fetch!(context, :conn) == conn
    end

    test "adds the current values in the context", %{conn: conn, config: config} do
      {:ok, context} =
        Juvet.Runner.run(conn, %{blah: "bleh", configuration: config})

      assert Map.fetch!(context, :blah) == "bleh"
    end

    test "parses the request into a request struct", %{
      conn: conn,
      config: config
    } do
      {:ok, context} = Juvet.Runner.run(conn, %{configuration: config})

      assert Map.fetch!(context, :request).params == %{
               "command" => "test",
               "team_id" => "T12345"
             }
    end

    test "finds the route that needs to be called", %{
      conn: conn,
      config: config
    } do
      {:ok, context} = Juvet.Runner.run(conn, %{configuration: config})

      assert Map.fetch!(context, :path) == "juvet.runner_test.test#action"
    end
  end
end
