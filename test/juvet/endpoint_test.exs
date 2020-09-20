defmodule Juvet.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

  describe "Juvet.Endpoint.start_link\1" do
    test "initializes with configuration for the endpoint" do
      config = [
        endpoint: [
          http: [port: 4002]
        ]
      ]

      start_supervised!({Juvet.Endpoint, config})

      conn = conn(:get, "/ping")

      IO.inspect(conn)

      child =
        Supervisor.which_children(Juvet.Endpoint)
        |> List.first()
        |> Kernel.elem(1)

      IO.inspect(Process.info(child))
    end
  end
end
