defmodule Juvet.SlackAPI.Users do
  alias Juvet.SlackAPI

  def info(options \\ %{}) do
    SlackAPI.request("users.info", options)
    |> SlackAPI.render_response()
  end
end
