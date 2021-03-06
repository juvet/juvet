defmodule Juvet.SlackAPI.Team do
  @moduledoc """
  A wrapper around the team methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Requests information on a specific team.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    team: {
      id: "T123456"
    }
  } = Juvet.SlackAPI.Team.info(%{token: token, team: team})
  """

  def info(options \\ %{}) do
    SlackAPI.request("team.info", options)
    |> SlackAPI.render_response()
  end
end
