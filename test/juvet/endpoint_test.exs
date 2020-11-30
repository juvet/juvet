defmodule Juvet.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Juvet.ConfigurationHelpers

  describe "Juvet.Endpoint.start_link/1" do
    setup do
      start_supervised!({Juvet.Endpoint, default_config()})

      :ok
    end

    test "initializes with configuration for slack events" do
      assert {:ok, response} =
               HTTPoison.post(
                 "http://127.0.0.1:8080/slack/events",
                 Poison.encode!(%{event: %{type: "app_uninstalled"}}),
                 [{"Content-Type", "application/json"}]
               )

      assert response.status_code == 200
    end

    test "returns a 404 if the path is not handled" do
      assert {:ok, response} = HTTPoison.get("http://127.0.0.1:8080/blah")
      assert response.status_code == 404
    end
  end
end
