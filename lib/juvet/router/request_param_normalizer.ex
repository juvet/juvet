defmodule Juvet.Router.RequestParamNormalizer do
  @moduledoc """
  Module to normalize the `Request#raw_params` based on the platform for the request.
  """

  alias Juvet.Router.Request

  defmodule SlackRequestParamNormalizer do
    @moduledoc """
    Normalizes Slack `Request` params.
    """

    def normalize(%Request{raw_params: nil} = request), do: request

    def normalize(%Request{raw_params: %{"event" => _event} = params} = request) do
      %{request | params: normalized_event(params)}
    end

    def normalize(%Request{raw_params: %{"payload" => payload}} = request) do
      %{request | params: normalized_payload(payload)}
    end

    def normalize(%Request{raw_params: raw_params} = request),
      do: %{request | params: normalized_payload(raw_params)}

    defp channel_id(%{"channel" => %{"id" => channel_id}}), do: channel_id
    defp channel_id(%{"channel" => channel_id}), do: channel_id
    defp channel_id(%{"channel_id" => channel_id}), do: channel_id
    defp channel_id(_payload), do: nil

    defp team_id(%{"team" => %{"id" => team_id}}), do: team_id
    defp team_id(%{"team_id" => team_id}), do: team_id
    defp team_id(_payload), do: nil

    defp user_id(%{"user" => %{"id" => user_id}}), do: user_id
    defp user_id(%{"user" => user_id}), do: user_id
    defp user_id(%{"user_id" => user_id}), do: user_id
    defp user_id(_payload), do: nil

    defp normalized_event(%{"event" => event} = params),
      do: %{channel_id: channel_id(event), team_id: team_id(params), user_id: user_id(event)}

    defp normalized_payload(payload),
      do: %{channel_id: channel_id(payload), team_id: team_id(payload), user_id: user_id(payload)}
  end

  def normalize(%Request{platform: :slack} = request),
    do: SlackRequestParamNormalizer.normalize(request)

  def normalize(%Request{platform: :unknown} = request), do: request
end
