defmodule Juvet.Router.OAuthRouter do
  @moduledoc """
  Routes to the correct oauth provider based on the platform.
  """

  alias Juvet.OAuth

  @spec url_for(atom(), atom(), map(), Keyword.t()) :: String.t() | nil
  def url_for(platform, phase, configuration, params \\ [])

  def url_for(:slack, :request, configuration, params) do
    OAuth.Slack.authorize_url!(slack_request_params(configuration) |> Keyword.merge(params))
  end

  def url_for(_platform, _phase, _configuration, _params), do: nil

  defp params_from_config(config, keys) do
    keys
    |> Enum.map(fn key -> {key, get_in(config, [key])} end)
    |> Keyword.new()
  end

  defp slack_request_params(slack: slack_config),
    do:
      slack_config
      |> params_from_config([
        :app_id,
        :client_id,
        :client_secret,
        :scope,
        :user_scope,
        :redirect_uri
      ])

  defp slack_request_params(_configuration), do: []
end
