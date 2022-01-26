defmodule Juvet.Middleware do
  # TODO: Eventually the middleware grouping will be retrieved from the Router and filtered by the group_name
  # For now, we hardcode

  def group(:partial) do
    [{Juvet.Middleware.ActionGenerator}, {Juvet.Middleware.ActionRunner}]
  end

  def group(:all) do
    [
      {Juvet.Middleware.ParseRequest},
      {Juvet.Middleware.IdentifyRequest},
      {Juvet.Middleware.Slack.VerifyRequest},
      {Juvet.Middleware.RouteRequest}
    ]
  end
end
