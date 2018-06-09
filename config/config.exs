use Mix.Config

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes",
  custom_cassette_library_dir: "test/fixtures/custom_cassettes",
  filter_sensitive_data: [
    [pattern: "<PASSWORD>.+</PASSWORD>", placeholder: "PASSWORD_PLACEHOLDER"],
    [pattern: "token=([^&#]*)", placeholder: "token=***"]
  ],
  filter_request_headers: [
    "X-Slack-Req-Id",
    "X-Via",
    "X-Amz-Cf-Id"
  ]
