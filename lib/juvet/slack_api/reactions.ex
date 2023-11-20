defmodule Juvet.SlackAPI.Reactions do
  @moduledoc """
  A wrapper around the reactions methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Adds a reaction to an item.

  Returns a map of the Slack response.

  ## Example

  %{ok: true} =
    Juvet.SlackAPI.Reactions.add(%{token: token, channel: "C12345", name: "thumbsup", timestamp: "12345.678"})
  """
  @spec add(map()) :: {:ok, map()} | {:error, map()}
  def add(options \\ %{}), do: request_and_render("reactions.add", options)

  @doc """
  Gets reactions for an item.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    type: "message",
    message: %{
      ts: "12345.678",
      reactions: [
        %{name: "thumbsup", count: 3, users: ["U12345", "U23456", "U34567"]},
      ]
    }
  } = Juvet.SlackAPI.Reactions.get(%{token: token, channel: "C12345", timestamp: "12345.678"})
  """
  @spec get(map()) :: {:ok, map()} | {:error, map()}
  def get(options \\ %{}), do: request_and_render("reactions.get", options)

  @doc """
  Lists reactions made by a user.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    items: [
      %{
        type: "message",
        channel: "C12345",
        message: %{
          ts: "12345.678",
          reactions: [
            %{name: "thumbsup", count: 3, users: ["U12345", "U23456", "U34567"]},
          ]
        }
      }
    ]
  } = Juvet.SlackAPI.Reactions.list(%{token: token, user: "U12345", limit: 20})
  """
  @spec list(map()) :: {:ok, map()} | {:error, map()}
  def list(options \\ %{}), do: request_and_render("reactions.list", options)

  @doc """
  Removes a reaction from an item.

  Returns a map of the Slack response.

  ## Example

  %{ok: true} =
    Juvet.SlackAPI.Reactions.remove(%{token: token, channel: "C12345", name: "thumbsup", timestamp: "12345.678"})
  """
  @spec remove(map()) :: {:ok, map()} | {:error, map()}
  def remove(options \\ %{}), do: request_and_render("reactions.remove", options)

  defp request_and_render(method, options) do
    options = options |> transform_options

    SlackAPI.make_request(method, options)
    |> SlackAPI.render_response()
  end

  defp transform_options(options) do
    options
    |> Enum.filter(fn {_key, value} -> !is_nil(value) end)
    |> Enum.into(%{})
  end
end
