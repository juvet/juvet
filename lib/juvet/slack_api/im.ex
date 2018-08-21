defmodule Juvet.SlackAPI.IM do
  alias Juvet.SlackAPI

  def open(options \\ %{}) do
    SlackAPI.request("im.open", options)
    |> SlackAPI.render_response()
  end
end
