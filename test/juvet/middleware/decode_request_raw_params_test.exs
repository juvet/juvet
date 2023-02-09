defmodule Juvet.Middleware.DecodeRequestRawParamsTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.DecodeRequestRawParams
  alias Juvet.Router.Request

  describe "call/1" do
    setup do
      params = %{"payload" => "{\"foo\": \"bar\"}"}
      request = Request.new(%{params: params})

      [context: %{request: %{request | platform: :slack}}]
    end

    test "decodes the request parameters based on the request platform", %{context: context} do
      assert {:ok, %{request: %{raw_params: raw_params}}} = DecodeRequestRawParams.call(context)
      assert raw_params == %{"payload" => %{"foo" => "bar"}}
    end

    test "does not add decode parameters if there is no request" do
      assert {:ok, context} = DecodeRequestRawParams.call(%{})
      refute Map.get(context, :request)
    end
  end
end
