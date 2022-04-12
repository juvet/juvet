defmodule Juvet.SlackAPI.Views do
  @moduledoc """
  A wrapper around the views methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Opens a view for a user.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    view: {
      id: "VIEW1"
    }
  } = Juvet.SlackAPI.Views.open(%{token: token, trigger_id: trigger_id, view: view})
  """
  def open(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("views.open", options)
    |> SlackAPI.render_response()
  end

  defp transform_options(options), do: options
end
