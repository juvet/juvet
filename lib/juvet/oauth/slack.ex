defmodule Juvet.OAuth.Slack do
  @moduledoc """
  Uses the OAuth2 Strategy to provide OAuth functionality for Slack.
  """

  use OAuth2.Strategy
  alias OAuth2.{Client, Strategy}

  @spec authorize_url!(params :: keyword()) :: String.t()
  def authorize_url!(params \\ []), do: Client.authorize_url!(client(), params)

  def client do
    config()
    |> Client.new()
    |> Client.put_serializer("application/json", Poison)
  end

  # Strategy callbacks

  def authorize_url(client, params), do: Strategy.AuthCode.authorize_url(client, params)

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> Strategy.AuthCode.get_token(params, headers)
  end

  # Private API

  defp config do
    [
      strategy: __MODULE__,
      site: "https://slack.com/api",
      authorize_url: "https://slack.com/oauth/v2/authorize",
      token_url: "/oauth.v2.access"
    ]
  end
end
