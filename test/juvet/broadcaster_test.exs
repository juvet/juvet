defmodule Juvet.Broadcaster.BroadcasterTest do
  use ExUnit.Case, async: true

  alias Juvet.{Broadcaster}

  describe "Broadcaster.start_link/0" do
    test "returns a pid" do
      assert {:ok, _pid} = Broadcaster.start_link()
    end
  end
end
