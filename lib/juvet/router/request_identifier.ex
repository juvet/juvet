defmodule Juvet.Router.RequestIdentifier do
  @moduledoc """
  Identifies the origin of a `Request`
  """

  alias Juvet.Router.Request

  defmodule SlackRequestIdentifier do
    @moduledoc """
    Identifies requests from Slack.
    """

    @host "slack.com"

    def host, do: @host

    @spec platform(Juvet.Router.Request.t()) :: atom() | nil
    def platform(%Request{} = request) do
      if from_platform?(request) || oauth?(request), do: :slack
    end

    defp oauth?(request) do
      Request.get?(request) && Request.from_host?(request, host())
    end

    defp from_platform?(request) do
      Request.get_header(request, "x-slack-signature")
      |> Enum.empty?()
      |> Kernel.not()
    end
  end

  @spec platform(Juvet.Router.Request.t()) :: atom()
  def platform(%Request{} = request) do
    SlackRequestIdentifier.platform(request) || :unknown
  end
end
