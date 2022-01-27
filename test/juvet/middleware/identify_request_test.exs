defmodule Juvet.Middleware.IdentifyRequestTest do
  use ExUnit.Case, async: true

  describe "call/1" do
    test "identifies slack requests" do
      request =
        Juvet.Router.Request.new(%{
          req_headers: [{"x-slack-signature", "blah"}]
        })

      assert {:ok, ctx} =
               Juvet.Middleware.IdentifyRequest.call(%{request: request})

      assert ctx[:request].platform == :slack
    end

    test "identifies slack request no matter where the header is" do
      request =
        Juvet.Router.Request.new(%{
          req_headers: [
            {"x-something-else", "bleh"},
            {"x-slack-signature", "blah"}
          ]
        })

      assert {:ok, %{request: %{platform: :slack}}} =
               Juvet.Middleware.IdentifyRequest.call(%{request: request})
    end

    test "returns unknown if there is no request" do
      assert {:ok, ctx} = Juvet.Middleware.IdentifyRequest.call(%{})

      assert ctx == %{}
    end

    test "returns unknown if there are no headers in the request" do
      request = Juvet.Router.Request.new(%{})

      assert {:ok, ctx} =
               Juvet.Middleware.IdentifyRequest.call(%{request: request})

      assert ctx[:request].platform == :unknown
    end

    test "returns unknown if the headers were not identified" do
      request =
        Juvet.Router.Request.new(%{
          req_headers: [{"blah", "blah"}]
        })

      assert {:ok, ctx} =
               Juvet.Middleware.IdentifyRequest.call(%{request: request})

      assert ctx[:request].platform == :unknown
    end
  end
end
