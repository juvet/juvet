defmodule Juvet.Router.RequestParamNormalizer do
  @moduledoc """
  Module to normalize the `Request#raw_params` based on the platform for the request.
  """

  alias Juvet.Router.Request

  defmodule SlackRequestParamNormalizer do
    @moduledoc """
    """

    def normalize(%Request{raw_params: nil} = request), do: request

    def normalize(%Request{raw_params: %{"payload" => payload}} = request) do
      %{request | params: normalized_params(payload)}
    end

    def normalize(%Request{raw_params: _raw_params} = request), do: request

    defp user_id(%{"user" => %{"id" => user_id}}), do: user_id
    defp user_id(_payload), do: nil

    defp normalized_params(payload), do: %{user_id: user_id(payload)}
  end

  def normalize(%Request{platform: :slack} = request),
    do: SlackRequestParamNormalizer.normalize(request)

  def normalize(%Request{platform: :unknown} = request), do: request
end
