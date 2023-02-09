defmodule Juvet.Router.RequestParamDecoder do
  @moduledoc """
  Module to decode the `Request#params` based on the platform for the request.
  """

  alias Juvet.Router.Request

  defmodule SlackRequestParamDecoder do
    @moduledoc """
    Decodes Slack `Request` params.
    """

    def decode(%Request{raw_params: nil} = request), do: request

    def decode(%Request{raw_params: %{"payload" => payload}} = request) do
      case Poison.decode(payload) do
        {:ok, payload} ->
          %{request | raw_params: put_in(request.raw_params, ["payload"], payload)}

        {:error, _error} ->
          request
      end
    end

    def decode(%Request{raw_params: _raw_params} = request), do: request
  end

  def decode(%Request{platform: :slack} = request), do: SlackRequestParamDecoder.decode(request)
  def decode(%Request{platform: :unknown} = request), do: request
end
