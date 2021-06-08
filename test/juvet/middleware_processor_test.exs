defmodule Juvet.MiddlewareProcessorTest do
  use ExUnit.Case, async: true

  describe "Juvet.Middleware.process/1" do
    defmodule TestMiddleware1 do
      def call(context) do
        Map.put(context, :middleware1, "was here")
      end
    end

    setup do
      [context: %{middleware: [{TestMiddleware1}]}]
    end

    test "returns the context modifications that occurred", %{context: context} do
      context = Juvet.MiddlewareProcessor.process(context)

      assert Map.has_key?(context, :middleware1)
      assert Map.fetch!(context, :middleware1) == "was here"
    end
  end
end
