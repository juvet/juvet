defmodule Juvet.Queue.InMemoryQueue.InMemoryQueueTest do
  use ExUnit.Case, async: true

  alias Juvet.Queue.{InMemoryQueue}

  describe "InMemoryQueue.start_link/0" do
    test "returns a pid" do
      assert {:ok, _pid} = InMemoryQueue.start_link()
    end
  end
end
