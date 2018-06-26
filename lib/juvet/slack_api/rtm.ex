defmodule Juvet.SlackAPI.RTM do
  alias Juvet.SlackAPI

  def connect(options \\ %{}) do
    SlackAPI.request("rtm.connect", options)
    |> SlackAPI.handle_response()
  end
end
