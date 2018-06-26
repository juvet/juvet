defmodule Juvet.SlackAPI do
  use HTTPoison.Base

  alias Juvet.SlackAPI

  def handle_response({:ok, %{ok: false} = body}) do
    {:error, body}
  end

  def handle_response({:ok, %{ok: true} = body}) do
    {:ok, body}
  end

  def parse_response({:ok, %HTTPoison.Response{body: body}}) do
    response = body |> Poison.decode!(keys: :atoms)
    {:ok, response}
  end

  def process_url(endpoint) do
    "https://slack.com/api/" <> endpoint
  end

  def request(endpoint, body) do
    SlackAPI.get(
      endpoint,
      headers(),
      params: body
    )
  end

  defp headers do
    %{
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end
end
