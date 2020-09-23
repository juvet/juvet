defmodule Juvet.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Juvet.ConfigurationHelpers

  setup_all :setup_reset_config_on_exit
  setup :setup_reset_config

  describe "Juvet.Endpoint.start_link/0" do
    test "initializes with configuration for the port" do
      Application.put_env(:juvet, :endpoint, http: [port: 4002])

      start_supervised!(Juvet.Endpoint)

      assert {:ok, _ref} =
               :hackney.get("http://127.0.0.1:4002/ping", [], "", async: :once)
    end

    @tag :skip
    test "initializes with configuration for the scheme" do
      Application.put_env(:juvet, :endpoint, https: [])

      start_supervised!(Juvet.Endpoint)

      assert {:ok, _ref} =
               :hackney.get("https://127.0.0.1:80/ping", [], "", async: :once)
    end
  end
end
