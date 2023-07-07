defmodule Juvet.Router.RequestIdentifier do
  @moduledoc """
  Identifies the origin of a `Request`
  """

  alias Juvet.Router.Request

  defmodule SlackRequestIdentifier do
    @moduledoc """
    Identifies requests from Slack.
    """

    @spec platform(Juvet.Router.Request.t(), Keyword.t()) :: atom() | nil
    def platform(%Request{} = request, configuration) do
      if from_platform?(request) || oauth?(request, configuration), do: :slack
    end

    defp oauth?(request, configuration) do
      Request.get?(request) &&
        match_oauth_paths?(request, Juvet.Config.oauth_paths(configuration)[:slack])
    end

    defp from_platform?(request) do
      Request.get_header(request, "x-slack-signature")
      |> Enum.empty?()
      |> Kernel.not()
    end

    defp match_oauth_paths?(request, paths) do
      paths
      |> Enum.any?(fn path ->
        Request.match_path?(request, path[:path])
      end)
    end
  end

  @spec platform(Juvet.Router.Request.t(), Keyword.t()) :: atom()
  def platform(%Request{} = request, configuration) do
    SlackRequestIdentifier.platform(request, configuration) || :unknown
  end
end
