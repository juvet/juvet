defmodule Juvet.Middleware do
  @moduledoc """
  Middleware groups to define what middleware is run during the request flow.
  """

  def group(:partial) do
    [{Juvet.Middleware.ActionGenerator}, {Juvet.Middleware.ActionRunner}]
  end

  def group(:all) do
    [
      {Juvet.Middleware.ParseRequest},
      {Juvet.Middleware.IdentifyRequest},
      {Juvet.Middleware.Slack.VerifyRequest},
      {Juvet.Middleware.RouteRequest}
    ] ++ group(:partial)
  end
end
