defmodule Juvet.RunnerTest do
  use ExUnit.Case, async: true

  describe "Juvet.Runner.route/2" do
    defmodule ControllerController do
      def action do
      end
    end

    setup do
      [path: "controller#action"]
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

      assert Map.fetch!(context, :action) == {:ControllerController, "action"}
    end
  end
end
