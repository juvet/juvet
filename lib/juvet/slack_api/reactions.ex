defmodule Juvet.SlackAPI.Reactions do
  @moduledoc """
  A wrapper around the reactions methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @spec add(map()) :: {:ok, map()} | {:error, map()}
  def add(options \\ %{}), do: request_and_render("reactions.add", options)

  @spec get(map()) :: {:ok, map()} | {:error, map()}
  def get(options \\ %{}), do: request_and_render("reactions.get", options)

  @spec list(map()) :: {:ok, map()} | {:error, map()}
  def list(options \\ %{}), do: request_and_render("reactions.list", options)

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
