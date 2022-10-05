defmodule Juvet.SlackRoutes do
  @moduledoc """
  Creates routes necessary for incoming Slack messages from configuration.
  """

  defmacro __using__(_opts) do
    quote do
      config = Juvet.configuration()

      if Juvet.Config.slack_configured?(config) do
        defaults = %{
          actions_endpoint: nil,
          commands_endpoint: nil,
          events_endpoint: nil
        }

        %{
          actions_endpoint: actions_endpoint,
          commands_endpoint: commands_endpoint,
          events_endpoint: events_endpoint
        } = Map.merge(defaults, Juvet.Config.slack(config))

        if events_endpoint,
          do: post(events_endpoint, to: Juvet.SlackEventRoute)

        if commands_endpoint,
          do: post(commands_endpoint, to: Juvet.SlackCommandRoute)

        if actions_endpoint,
          do: post(actions_endpoint, to: Juvet.SlackActionRoute)
      end
    end
  end
end
