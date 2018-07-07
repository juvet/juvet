defmodule Juvet.ConnectionFactorySupervisor.ConnectionFactorySupervisorTest do
  use ExUnit.Case, async: true

  alias Juvet.{ConnectionFactorySupervisor, ConnectionFactory}

  describe "ConnectionFactorySupervisor.start_link\0" do
    test "starts the connection factory" do
      ConnectionFactorySupervisor.start_link()

      assert Process.whereis(ConnectionFactory) |> Process.alive?()
    end
  end
end
