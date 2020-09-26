defmodule Juvet do
  use Application

  import Supervisor.Spec

  def start(_types, _args) do
    children = [
      supervisor(PubSub, []),
      supervisor(Juvet.BotFactorySupervisor, []),
      supervisor(Juvet.ConnectionFactorySupervisor, []),
      supervisor(Juvet.BotShop, []),
      supervisor(Juvet.Endpoint, [])
    ]

    children = children ++ slack_processes()

    Supervisor.start_link(children, strategy: :one_for_all)
  end

  defp slack_processes do
    slack_events_processes(Juvet.Config.slack_configured?())
  end

  defp slack_events_processes(true),
    do: [supervisor(Juvet.Slack.EventsListener, [])]

  defp slack_events_processes(false), do: []
end
