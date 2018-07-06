defmodule Juvet.BotFactory.BotFactoryTest do
  use ExUnit.Case, async: true

  alias Juvet.{BotFactory, BotFactorySupervisor}

  describe "BotFactory.start_link\2" do
    test "adds itself as a child to a supervisor" do
      [_ | t] = Supervisor.which_children(BotFactorySupervisor)

      assert [{Juvet.BotFactory, _pid, :worker, [Juvet.BotFactory]}] = t
    end

    test "listens for new slack connections and adds a bot" do
      subscribers = PubSub.subscribers(:new_slack_connection)

      assert subscribers == [Process.whereis(BotFactory)]
    end
  end
end
