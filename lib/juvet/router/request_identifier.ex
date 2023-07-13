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

    @spec oauth?(Juvet.Router.Request.t(), Keyword.t()) :: boolean()
    def oauth?(request, configuration) do
      Request.get?(request) &&
        match_oauth_paths?(request, Juvet.Config.oauth_paths(configuration)[:slack])
    end

    @spec oauth_path(Juvet.Router.Request.t(), Keyword.t()) :: atom()
    def oauth_path(request, configuration) do
      Juvet.Config.oauth_paths(configuration)[:slack]
      |> Enum.find_value(fn path ->
        if Request.match_path?(request, path[:path]), do: path[:type]
      end)
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

  @spec oauth?(Juvet.Router.Request.t(), Keyword.t()) :: boolean()
  def oauth?(%Request{platform: :slack} = request, configuration),
    do: SlackRequestIdentifier.oauth?(request, configuration)

  def oauth?(%Request{platform: :unknown}, _configuration), do: false

  @spec oauth_path(Juvet.Router.Request.t(), Keyword.t()) :: atom()
  def oauth_path(%Request{platform: :slack} = request, configuration),
    do: SlackRequestIdentifier.oauth_path(request, configuration)

  def oauth_path(%Request{platform: :unknown}, _configuration), do: nil

  @spec platform(Juvet.Router.Request.t(), Keyword.t()) :: atom()
  def platform(%Request{} = request, configuration) do
    SlackRequestIdentifier.platform(request, configuration) || :unknown
  end
end
