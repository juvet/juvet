defmodule Juvet.SlackAPI do
  use HTTPoison.Base

  alias Juvet.SlackAPI

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

  def headers do
    %{
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end
end
