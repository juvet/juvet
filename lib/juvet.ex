defmodule Juvet do
  use Application

  def start(_types, _args) do
    config = Application.get_all_env(:juvet)

    children = [
      Supervisor.Spec.supervisor(PubSub, []),
      Supervisor.Spec.supervisor(Juvet.BotFactorySupervisor, [config]),
      Supervisor.Spec.supervisor(Juvet.ConnectionFactorySupervisor, []),
      Supervisor.Spec.supervisor(Juvet.BotShop, []),
      Supervisor.Spec.supervisor(Juvet.Endpoint, [])
    ]

    children = children ++ slack_processes()

    Supervisor.start_link(children, strategy: :one_for_all)
  end

  defp slack_processes do
    slack_events_processes(Juvet.Config.slack_configured?())
  end

  defp slack_events_processes(true),
    do: [Supervisor.Spec.supervisor(Juvet.Slack.EventsListener, [])]

  defp slack_events_processes(false), do: []
end
