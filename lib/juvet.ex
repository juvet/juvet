defmodule Juvet do
  use Application

  def start(_types, _args) do
    config = Application.get_all_env(:juvet)

    children = [
      Supervisor.Spec.supervisor(PubSub, []),
      Supervisor.Spec.supervisor(Juvet.BotFactorySupervisor, [config]),
      Supervisor.Spec.supervisor(Juvet.ConnectionFactorySupervisor, []),
      Supervisor.Spec.supervisor(Juvet.BotShop, [config]),
      Supervisor.Spec.supervisor(Juvet.Endpoint, [])
    ]

    children = children ++ slack_processes(config)

    Supervisor.start_link(children, strategy: :one_for_all)
  end

  defp slack_processes(config) do
    slack_events_processes(config, slack_events_configured?(config))
  end

  defp slack_events_processes(config, true),
    do: [Supervisor.Spec.supervisor(Juvet.Slack.EventsListener, [config])]

  defp slack_events_processes(_config, false), do: []

  defp slack_events_configured?(config) do
    Keyword.has_key?(
      Keyword.get(config, :slack) || [],
      :events_endpoint
    )
  end
end
