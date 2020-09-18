defmodule Juvet.BotFactory.BotFactoryTest do
  use ExUnit.Case

  import Juvet.ProcessHelpers

  alias Juvet.{BotFactory, BotFactorySupervisor, BotSupervisor}

  describe "BotFactory.start_link/2" do
    setup :setup_with_supervised_application!

    test "adds itself as a child to a supervisor" do
      [_ | t] = Supervisor.which_children(BotFactorySupervisor)

      assert [{Juvet.BotFactory, _pid, :worker, [Juvet.BotFactory]}] = t
    end

    test "listens for new slack connections and adds a bot" do
      subscribers = PubSub.subscribers(:new_slack_connection)

      assert Enum.member?(subscribers, Process.whereis(BotFactory))
    end
  end

  describe "BotFactory.add_bot\1" do
    setup :setup_with_supervised_application!

    @tag :skip
    test "adds a bot process to the bot supervisor" do
      :ok = BotFactory.add_bot(%{ok: true, team: %{domain: "Led Zeppelin"}})

      # Hack to ensure the child is mounted
      :timer.sleep(800)
      children = Supervisor.which_children(BotSupervisor)

      assert [{:undefined, _pid, :worker, [Juvet.BotServer]}] = children
    end
  end
end
