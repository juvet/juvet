defmodule Juvet.SlackRequestHelpers do
  @moduledoc """
  Test helpers for making Slack requests.
  """

  defmacro __using__(_) do
    quote do
      def slack_headers(
            params,
            signing_secret \\ generate_slack_signing_secret(),
            timestamp \\ NaiveDateTime.utc_now()
          ) do
        signature = generate_slack_signature(params, signing_secret, timestamp)
        timestamp = generate_slack_timestamp(timestamp)

        [
          {"x-slack-request-timestamp", timestamp},
          {"x-slack-signature", signature}
        ]
      end

      def generate_slack_signing_secret do
        :crypto.strong_rand_bytes(32)
      end

      def generate_slack_signature(
            params,
            signing_secret,
            timestamp \\ NaiveDateTime.utc_now()
          ) do
        params
        |> URI.encode_query()
        |> Juvet.SlackSigningSecret.generate(signing_secret, timestamp)
      end

      def generate_slack_timestamp(date_time \\ NaiveDateTime.utc_now()) do
        date_time
        |> Juvet.GregorianDateTime.to_seconds()
        |> to_string
      end
    end
  end
end
