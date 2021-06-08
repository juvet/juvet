defmodule Juvet.Middleware do
  def group(_name) do
    # TODO: Eventually this will be retrieved from the Router and filtered by the group_name

    [{Juvet.Middleware.ActionRunner}]
  end
end
