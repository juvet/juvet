defmodule Juvet.Router.OAuthRouter do
  @moduledoc """
  Routes to the correct oauth provider based on the platform.
  """

  alias Juvet.OAuth

  def auth_for(platform, configuration, params \\ [])

  def auth_for(:slack, configuration, params) do
    configuration
    |> Juvet.Config.slack()
    |> slack_callback_params()
    |> Keyword.merge(params)
    |> OAuth.Slack.get_token!()
    |> to_tuple()
  end

  def auth_for(_provider, _configuration, _params), do: nil

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

  defp slack_callback_params(nil), do: []

  defp slack_callback_params(slack_config),
    do:
      slack_config
      |> params_from_config([
        :client_id,
        :client_secret
      ])

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

  defp slack_strategy_error_tuple(%{token: %{other_params: %{"error" => error}}} = response) do
    {:error, error, response}
  end

  defp to_tuple(%{strategy: Juvet.OAuth.Slack, token: %{access_token: nil}} = response),
    do: slack_strategy_error_tuple(response)

  defp to_tuple(%{token: %{access_token: _}} = response), do: {:ok, response}
end
