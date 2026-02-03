defmodule Juvet.Template.Compiler.Slack.Elements.UrlInput do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.{DispatchActionConfig, Text}
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :url_input, attributes: attrs} = el) do
    %{type: "url_text_input"}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:initial_value, attrs[:initial_value])
    |> maybe_put(:placeholder, compile_placeholder(attrs))
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
    |> maybe_put(:dispatch_action_config, compile_dispatch_action_config(el))
  end

  defp compile_placeholder(%{placeholder: %{text: _} = attrs}),
    do: Text.compile(attrs.text, Map.put_new(attrs, :type, :plain_text))

  defp compile_placeholder(%{placeholder: text}) when is_binary(text),
    do: Text.compile(text, %{type: :plain_text})

  defp compile_placeholder(_), do: nil

  defp compile_dispatch_action_config(%{children: %{dispatch_action_config: config}}),
    do: DispatchActionConfig.compile(config)

  defp compile_dispatch_action_config(_), do: nil
end
