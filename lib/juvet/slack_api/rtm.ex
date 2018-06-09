defmodule Juvet.SlackAPI.RTM do
  alias Juvet.SlackAPI

  def connect(options \\ %{}) do
    SlackAPI.request("rtm.connect", options) |> handle_response
  end

  def handle_response({:ok, %HTTPoison.Response{body: body}}) do
    response = body |> Poison.decode!(keys: :atoms)

    {:ok, response}
  end
end
