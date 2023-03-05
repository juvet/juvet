defmodule Juvet.Middleware.ActionRunnerTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.ActionRunner

  defmodule TestController do
    def action(context) do
      if context[:pid], do: send(context.pid, :called_controller)

      context = Map.merge(context, %{hello: "world"})

      {:ok, context}
    end

    def action_with_bad_return(_context) do
      "blah"
    end
  end

  describe "call/1" do
    setup do
      controller = :"Elixir.Juvet.Middleware.ActionRunnerTest.TestController"

      [
        controller: controller,
        context: %{
          action: {controller, :action}
        }
      ]
    end

    test "returns an error if the context does not contain an action" do
      result = ActionRunner.call(%{})

      assert result == {:error, "`action` missing in the `context`"}
    end

    test "returns an error if the controller action could not be called" do
      result = ActionRunner.call(%{action: {:TestController, :action}})

      assert result == {:error, "`TestController.action/1` is not defined"}
    end

    test "returns an error if the function action could not be called" do
      assert {:error, _} = ActionRunner.call(%{action: fn -> nil end})
    end

    test "calls the controller module and action with the context", %{
      context: context
    } do
      assert {:ok, _ctx} = ActionRunner.call(Map.merge(context, %{pid: self()}))

      assert_received :called_controller
    end

    test "calls the function action with the context" do
      context = %{
        pid: self(),
        action: fn %{pid: pid} = context ->
          send(pid, :called_function)
          {:ok, context}
        end
      }

      assert {:ok, _ctx} = ActionRunner.call(context)

      assert_received :called_function
    end

    test "returns the updated context from the controller", %{context: context} do
      assert {:ok, %{hello: "world"}} = ActionRunner.call(context)
    end

    test "requires an ok tuple with the context to be returned", %{controller: controller} do
      result = ActionRunner.call(%{action: {controller, :action_with_bad_return}})

      assert result ==
               {:error,
                "`action_with_bad_return/1` is required to return the `context` in an `:ok` tuple or an `:error` tuple"}
    end
  end
end
