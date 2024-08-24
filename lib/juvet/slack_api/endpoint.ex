defmodule Juvet.SlackAPI.Endpoint do
  alias Juvet.SlackAPI

  def request_and_render(method, options) do
    options = options |> transform_options

    SlackAPI.make_request(method, options)
    |> SlackAPI.render_response()
  end

  defp transform_options(options) do
    options
    |> Enum.filter(fn {_key, value} -> !is_nil(value) end)
    |> Enum.into(%{})
  end

  defmacro __using__(_) do
    quote do
      alias Juvet.SlackAPI

      import Juvet.SlackAPI.Endpoint
    end
  end
end
