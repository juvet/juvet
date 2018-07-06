defmodule Juvet.SlackAPI do
  use HTTPoison.Base

  alias Juvet.SlackAPI

  @moduledoc """
  Helper methods to help process the response from Slack.
  """

  @doc ~S"""
  Returns an error tuple if the body contains an `ok: false` node.
  """
  def handle_response({:ok, %{ok: false} = body}) do
    {:error, body}
  end

  @doc ~S"""
  Returns an ok tuple if the body contains an `ok: true` node.
  """
  def handle_response({:ok, %{ok: true} = body}) do
    {:ok, body}
  end

  @doc ~S"""
  Decodes a JSON response and converts it into a Map.
  """
  def parse_response({:ok, %HTTPoison.Response{body: body}}) do
    response = body |> Poison.decode!(keys: :atoms)
    {:ok, response}
  end

  @doc """
  Parses and handles the response from the Slack API.
  """
  def render_response(tuple), do: parse_response(tuple) |> handle_response

  @doc ~S"""
  Returns the url for what url the API should use a the base url along
  with the current endpoint.
  """
  def process_url(endpoint) do
    url = Application.get_env(:slack, :url, "https://slack.com")
    "#{url}/api/#{endpoint}"
  end

  @doc ~S"""
  Make the request to the endpoint and returns that response.
  """
  def request(endpoint, body) do
    SlackAPI.get(
      endpoint,
      headers(),
      params: body
    )
  end

  @doc false
  defp headers do
    %{
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end
end
