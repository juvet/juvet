defmodule Juvet.Router.OAuthRouter do
  @moduledoc """
  Routes to the correct oauth provider based on the platform.
  """

  alias Juvet.OAuth

  @spec url_for(atom(), atom(), Keyword.t(), Keyword.t()) :: String.t() | nil
  def url_for(platform, phase, configuration, params \\ [])

  def url_for(:slack, :request, configuration, params) do
    configuration
    |> Juvet.Config.slack()
    |> slack_request_params()
    |> Keyword.merge(params)
    |> OAuth.Slack.authorize_url!()
  end

  def url_for(_platform, _phase, _configuration, _params), do: nil

  defp params_from_config(config, keys) do
    keys
    |> Enum.map(fn key -> {key, get_in(config, [key])} end)
    |> Keyword.new()
  end

  defp slack_request_params(nil), do: []

  defp slack_request_params(slack_config),
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
end
