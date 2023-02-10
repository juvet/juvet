defmodule Juvet.Middleware.DecodeRequestParamsTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.DecodeRequestParams
  alias Juvet.Router.Request

  describe "call/1" do
    setup do
      params = %{"payload" => "{\"foo\": \"bar\"}"}
      request = Request.new(%{params: params})

      [context: %{request: %{request | platform: :slack}}]
    end

    test "decodes the request parameters based on the request platform", %{context: context} do
      assert {:ok, %{request: %{raw_params: raw_params}}} = DecodeRequestParams.call(context)
      assert raw_params == %{"payload" => %{"foo" => "bar"}}
    end

    test "does not add decode parameters if there is no request" do
      assert {:ok, context} = DecodeRequestParams.call(%{})
      refute Map.get(context, :request)
    end
  end
end
