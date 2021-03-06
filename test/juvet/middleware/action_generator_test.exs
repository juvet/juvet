defmodule Juvet.Middleware.ActionGeneratorTest do
  use ExUnit.Case, async: true

  describe "Juvet.Middleware.ActionGenerator.call/1" do
    setup do
      [context: %{path: "test#action"}]
    end

    test "returns an error if the context does not contain a path" do
      result = Juvet.Middleware.ActionGenerator.call(%{})

      assert result == {:error, "`path` missing in the `context`"}
    end

    test "returns an endpoint Tuple with the controller and action",
         %{
           context: context
         } do
      assert {:ok, ctx} = Juvet.Middleware.ActionGenerator.call(context)
      assert ctx[:action] == {:"Elixir.TestController", :action}
    end

    test "handle namespacing in the controller path" do
      assert {:ok, context} =
               Juvet.Middleware.ActionGenerator.call(%{
                 path: "namespace.test#action"
               })

      assert context[:action] == {:"Elixir.Namespace.TestController", :action}
    end
  end
end
