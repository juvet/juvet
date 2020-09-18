defmodule Juvet.ConnectionFactory.ConnectionFactoryTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Juvet.ProcessHelpers

  alias Juvet.{
    ConnectionFactory,
    ConnectionFactorySupervisor,
    ConnectionSupervisor
  }

  setup_all do
    start_supervised_application!()

    Juvet.FakeSlack.start_link()

    on_exit(fn ->
      Juvet.FakeSlack.stop()
    end)

    {:ok, token: "SLACK_BOT_TOKEN"}
  end

  describe "ConnectionFactory.start_link\1" do
    test "adds itself as a child to a supervisor" do
      [_ | t] = Supervisor.which_children(ConnectionFactorySupervisor)

      assert [
               {Juvet.ConnectionFactory, _pid, :worker,
                [Juvet.ConnectionFactory]}
             ] = t
    end
  end

  describe "ConnectionFactory.connect\2" do
    test "adds a connection process to the connection supervisor", %{
      token: token
    } do
      use_cassette "rtm/connect/successful" do
        pid = ConnectionFactory.connect(:slack, %{token: token})

        # Hack to ensure the child is mounted
        :timer.sleep(800)
        children = Supervisor.which_children(ConnectionSupervisor)

        assert [
                 {:undefined, ^pid, :worker, [Juvet.Connection.SlackRTM]}
               ] = children
      end
    end
  end
end
