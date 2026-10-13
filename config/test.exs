import Config

config :plug, :validate_header_keys_during_test, false

config :juvet,
  bot: MyBot

config :juvet, Juvet.HTTPClient.Req, plug: {Req.Test, Juvet.HTTPClient}

config :oauth2, adapter: Tesla.Mock
