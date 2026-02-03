defmodule Juvet.Template.Compiler.Slack.Objects.Option do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :option, attributes: %{text: text, value: value} = attrs}) do
    %{text: Text.compile(text, Map.put_new(attrs, :type, :plain_text)), value: value}
    |> maybe_put(:description, compile_description(attrs))
  end

  defp compile_description(%{description: desc}),
    do: %{type: "plain_text", text: desc}

  defp compile_description(_), do: nil
end
