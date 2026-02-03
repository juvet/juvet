defmodule Juvet.Template.Compiler.Slack.Elements.IconButton do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :icon_button, attributes: %{text: %{text: _} = text_attrs} = attrs}) do
    %{
      type: "icon_button",
      icon: attrs[:icon],
      text: Text.compile(text_attrs.text, Map.put_new(text_attrs, :type, :plain_text))
    }
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:value, attrs[:value])
    |> maybe_put(:accessibility_label, attrs[:accessibility_label])
    |> maybe_put(:visible_to_user_ids, attrs[:visible_to_user_ids])
  end

  def compile(%{element: :icon_button, attributes: %{text: text} = attrs}) do
    %{
      type: "icon_button",
      icon: attrs[:icon],
      text: Text.compile(text, Map.put_new(attrs, :type, :plain_text))
    }
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:value, attrs[:value])
    |> maybe_put(:accessibility_label, attrs[:accessibility_label])
    |> maybe_put(:visible_to_user_ids, attrs[:visible_to_user_ids])
  end
end
