defmodule Juvet.MiddlewareProcessorTest do
  use ExUnit.Case, async: true

  describe "Juvet.Middleware.process/1" do
    defmodule ErrorMiddleware do
      def call(_context) do
        {:error, "There was an error"}
      end
    end

    defmodule TestMiddleware do
      def call(context) do
        {:ok, Map.put(context, :middleware1, "was here")}
      end
    end

    setup do
      [context: %{middleware: [{TestMiddleware}]}]
    end

    test "returns the context modifications that occurred", %{context: context} do
      {:ok, context} = Juvet.MiddlewareProcessor.process(context)

      assert Map.has_key?(context, :middleware1)
      assert Map.fetch!(context, :middleware1) == "was here"
    end

    test "returns an error if there was an error", %{context: context} do
      {:error, error} =
        Juvet.MiddlewareProcessor.process(
          Map.merge(context, %{middleware: [{ErrorMiddleware}]})
        )

      assert error == "There was an error"
    end
  end
end
