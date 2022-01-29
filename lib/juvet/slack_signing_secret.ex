defmodule Juvet.SlackSigningSecret do
  @moduledoc """
  Module to generate a sha for a Slack request in order to verify the request is from Slack.
  """

  def generate(body, signing_secret, timestamp \\ NaiveDateTime.utc_now())

  def generate(body, signing_secret, timestamp) when is_integer(timestamp),
    do: generate(body, signing_secret, to_string(timestamp))

  def generate(body, signing_secret, timestamp) when is_binary(timestamp) do
    "v0=#{
      :crypto.mac(
        :hmac,
        :sha256,
        signing_secret,
        "v0:#{timestamp}:#{body}"
      )
      |> Base.encode16()
    }"
    |> String.downcase()
  end

  def generate(body, signing_secret, timestamp) do
    timestamp = Juvet.GregorianDateTime.to_seconds(timestamp) |> to_string
    generate(body, signing_secret, timestamp)
  end
end
