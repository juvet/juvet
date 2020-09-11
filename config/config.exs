use Mix.Config

config :juvet,
  bot: nil,
  slack: [
    events_endpoint: "/slack/events"
  ]

import_config "#{Mix.env()}.exs"
