defmodule Juvet.Connection.SlackRTM do
  use WebSockex

  alias Juvet.{SlackAPI}

  def start(%{token: _token} = parameters) do
    SlackAPI.RTM.connect(parameters)
    |> start_link
  end

  defp start_link({:ok, %{url: url}}) do
    WebSockex.start_link(url, __MODULE__, %{})
  end

  defp start_link({:error, _} = response), do: response
end
