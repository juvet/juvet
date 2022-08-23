defmodule Juvet.SlackAPI.Users do
  @moduledoc """
  A wrapper around the users methods on the Slack API.
  """

  alias Juvet.SlackAPI

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
end
