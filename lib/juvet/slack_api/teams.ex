defmodule Juvet.SlackAPI.Teams do
  @moduledoc """
  A wrapper around the team methods on the Slack API.
  """

  use Juvet.SlackAPI.Endpoint

  @doc """
  Requests information on a specific team.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    team: {
      id: "T123456"
    }
  } = Juvet.SlackAPI.Teams.info(%{token: token, team: team})
  """

  @spec info(map()) :: {:ok, map()} | {:error, map()}
  def info(options \\ %{}), do: request_and_render("team.info", options)
end
