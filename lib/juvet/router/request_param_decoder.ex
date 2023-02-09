defmodule Juvet.Router.RequestParamDecoder do
  @moduledoc """
  Module to decode the `Request#params` based on the platform for the request.
  """

  alias Juvet.Router.Request

  defmodule SlackRequestParamDecoder do
    @moduledoc """
    Decodes Slack `Request` params.
    """

    def decode(%Request{params: nil} = request), do: request

    def decode(%Request{params: %{"payload" => payload}} = request) do
      case Poison.decode(payload) do
        {:ok, payload} -> %{request | params: put_in(request.params, ["payload"], payload)}
        {:error, _error} -> request
      end
    end

    def decode(%Request{params: _params} = request), do: request
  end

  def decode(%Request{platform: :slack} = request), do: SlackRequestParamDecoder.decode(request)
  def decode(%Request{platform: :unknown} = request), do: request
end
