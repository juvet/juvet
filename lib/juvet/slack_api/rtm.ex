defmodule Juvet.SlackAPI.RTM do
  alias Juvet.SlackAPI

  def connect(options \\ %{}) do
    SlackAPI.request("rtm.connect", options)
    |> SlackAPI.render_response()
  end
end
