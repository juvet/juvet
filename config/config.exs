use Mix.Config

config :juvet,
  slack: [
    events_endpoint: "/slack/events"
  ]

import_config "#{Mix.env()}.exs"
