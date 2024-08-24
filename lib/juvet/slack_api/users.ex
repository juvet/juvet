defmodule Juvet.SlackAPI.Users do
  @moduledoc """
  A wrapper around the users methods on the Slack API.
  """

  use Juvet.SlackAPI.Endpoint

  @doc """
  Requests information on a specific user.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    user: {
      id: "U123456"
    }
  } = Juvet.SlackAPI.Users.info(%{token: token, user: user})
  """

  @spec info(map()) :: {:ok, map()} | {:error, map()}
  def info(options \\ %{}) do
    SlackAPI.make_request("users.info", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Lists all users on a team.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    members: [
      %{
        id: "U1234",
        team_id: "T12345",
        deleted: false,
        name: "Jimmy Page",
        profile: %{}
      }
    ]
  } = Juvet.SlackAPI.Ysers.list(%{token: token, limit: 20})
  """
  @spec list(map()) :: {:ok, map()} | {:error, map()}
  def list(options \\ %{}), do: request_and_render("users.list", options)
end
