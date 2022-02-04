defmodule Juvet.Midddleware.BuildDefaultResponseTest do
  use ExUnit.Case, async: true

  alias Juvet.Midddleware.BuildDefaultResponse
  alias Juvet.Router.Request

  describe "call/1" do
    setup do
      request = Request.new(%{platform: :slack})

      [context: %{request: request}]
    end

    test "adds the default response to the request in the context", %{context: context} do
      assert {:ok, %{response: response}} = BuildDefaultResponse.call(context)
      assert response.status == 200
      assert response.body == ""
    end

    test "does not add the default response unless there is a request" do
      assert {:ok, context} = BuildDefaultResponse.call(%{})
      refute Map.get(context, :response)
    end
  end
end
