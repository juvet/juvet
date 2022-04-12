defmodule Juvet.SlackAPI.Views do
  @moduledoc """
  A wrapper around the views methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Push a view onto the stack of a root view.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    view: {
      id: "VIEW1"
    }
  } = Juvet.SlackAPI.Views.push(%{token: token, trigger_id: trigger_id, view: view})
  """
  def push(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("views.push", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Publish a static view for a User.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    view: {
      id: "VIEW1"
    }
  } = Juvet.SlackAPI.Views.publish(%{token: token, user_id: user_id, view: view})
  """
  def publish(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("views.publish", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Opens a view for a user.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    view: {
      id: "VIEW1"
    }
  } = Juvet.SlackAPI.Views.open(%{token: token, trigger_id: trigger_id, view: view})
  """
  def open(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("views.open", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Update an existing view.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    view: {
      id: "VIEW1"
    }
  } = Juvet.SlackAPI.Views.update(%{token: token, view_id: view_id, view: view})
  """
  def update(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("views.update", options)
    |> SlackAPI.render_response()
  end

  defp encode_view(nil), do: nil
  defp encode_view(view), do: Poison.encode!(view)

  defp transform_options(options) do
    options
    |> Map.get_and_update(:view, &{&1, encode_view(&1)})
    |> elem(1)
    |> Enum.filter(fn {_key, value} -> !is_nil(value) end)
    |> Enum.into(%{})
  end
end
