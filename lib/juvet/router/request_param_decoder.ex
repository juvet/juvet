defmodule Juvet.Router.RequestParamDecoder do
  alias Juvet.Router.Request

  defmodule SlackRequestParamDecoder do
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
