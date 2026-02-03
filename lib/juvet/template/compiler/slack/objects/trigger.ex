defmodule Juvet.Template.Compiler.Slack.Objects.Trigger do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :trigger, attributes: attrs}) do
    %{url: attrs.url}
    |> maybe_put(:customizable_input_parameters, attrs[:customizable_input_parameters])
  end
end
