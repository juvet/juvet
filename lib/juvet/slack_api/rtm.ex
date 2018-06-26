defmodule Juvet.SlackAPI.RTM do
  alias Juvet.SlackAPI

  def connect(options \\ %{}) do
    SlackAPI.request("rtm.connect", options)
    |> SlackAPI.parse_response()
    |> SlackAPI.handle_response()
  end
end
