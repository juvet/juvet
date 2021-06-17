defmodule Juvet.RunnerTest do
  use ExUnit.Case, async: true

  defmodule TestController do
    def action(%{pid: pid}) do
      send(pid, :called_controller)
    end

    def action(_context) do
    end
  end

  describe "Juvet.Runner.route/2" do
    setup do
      [path: "juvet.runner_test.test#action"]
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
end
