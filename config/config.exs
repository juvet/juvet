use Mix.Config

config :juvet,
  slack: [
    actions_endpoint: "/slack/actions",
    commands_endpoint: "/slack/commands",
    events_endpoint: "/slack/events"
  ]

import_config "#{Mix.env()}.exs"
