defmodule Juvet.Middleware.ActionRunnerTest do
  use ExUnit.Case, async: true

  defmodule TestController do
    def action(context) do
      send(context.pid, :called_controller)
    end
  end

  describe "Juvet.Middleware.ActionRunner.call/1" do
    setup do
      [
        context: %{
          action: {:"Elixir.Juvet.Middleware.ActionRunnerTest.TestController", :action}
        }
      ]
    end

    test "returns an error if the context does not contain an action" do
      result = Juvet.Middleware.ActionRunner.call(%{})

      assert result == {:error, "`action` missing in the `context`"}
    end

    test "returns an error if the controller action could not be called" do
      result = Juvet.Middleware.ActionRunner.call(%{action: {:TestController, :action}})

      assert result == {:error, "`TestController.action/1` is not defined"}
    end

    test "calls the controller module and action with the context", %{
      context: context
    } do
      assert {:ok, ctx} = Juvet.Middleware.ActionRunner.call(Map.merge(context, %{pid: self()}))

      assert_received :called_controller
    end
  end
end
