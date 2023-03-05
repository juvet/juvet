defmodule Juvet.Middleware.ActionGeneratorTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.ActionGenerator

  describe "call/1" do
    setup do
      [context: %{path: "test#action"}]
    end

    test "returns an error if the context does not contain a path" do
      assert {:error, "`path` missing in the `context`"} = ActionGenerator.call(%{})
    end

    test "returns an error if the path is nil" do
      assert {:error, "`path` missing in the `context`"} = ActionGenerator.call(%{})
    end

    test "returns an endpoint Tuple with the controller and action when the path is a string",
         %{
           context: context
         } do
      assert {:ok, ctx} = ActionGenerator.call(context)
      assert ctx[:action] == {:"Elixir.TestController", :action}
    end

    test "handle namespacing in the controller path" do
      assert {:ok, context} =
               ActionGenerator.call(%{
                 path: "namespace.test#action"
               })

      assert context[:action] == {:"Elixir.Namespace.TestController", :action}
    end

    test "returns the path when the path is a function" do
      fun = &Kernel.is_struct/1

      assert {:ok, ctx} = ActionGenerator.call(%{path: fun})
      assert ctx[:action] == fun
    end
  end
end
