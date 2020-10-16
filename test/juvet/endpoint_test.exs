defmodule Juvet.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

  describe "Juvet.Endpoint.start_link/1" do
    test "initializes with configuration for an http scheme with options" do
      start_supervised!(
        {Juvet.Endpoint, %{scheme: :http, options: [port: 4002]}}
      )

      assert {:ok, _ref} =
               :hackney.get("http://127.0.0.1:4002/ping", [], "", async: :once)
    end
  end
end
