defmodule Juvet.Template.Compiler.Slack.Elements.Select do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.{
    ConfirmationDialog,
    ConversationFilter,
    Option,
    OptionGroup,
    Text
  }

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  @type_map %{
    static: "static_select",
    external: "external_select",
    users: "users_select",
    conversations: "conversations_select",
    channels: "channels_select"
  }

  @multi_type_map %{
    static: "multi_static_select",
    external: "multi_external_select",
    users: "multi_users_select",
    conversations: "multi_conversations_select",
    channels: "multi_channels_select"
  }

  def compile(%{element: :select, attributes: attrs} = el) do
    source = attrs[:source] || :static
    multiple = attrs[:multiple] || false

    type =
      if multiple,
        do: Map.fetch!(@multi_type_map, source),
        else: Map.fetch!(@type_map, source)

    %{type: type}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:placeholder, compile_placeholder(attrs))
    |> maybe_put(:focus_on_load, attrs[:focus_on_load])
    |> maybe_put(:max_selected_items, if(multiple, do: attrs[:max_selected_items]))
    |> compile_source(source, multiple, el)
    |> maybe_put(:confirm, compile_confirm(el))
  end

  defp compile_placeholder(%{placeholder: %{text: _} = attrs}),
    do: Text.compile(attrs.text, Map.put_new(attrs, :type, :plain_text))

  defp compile_placeholder(%{placeholder: text}) when is_binary(text),
    do: Text.compile(text, %{type: :plain_text})

  defp compile_placeholder(_), do: nil

  # Static source
  defp compile_source(map, :static, multiple, el) do
    map
    |> put_options_or_groups(el)
    |> put_initial_option_or_options(el, multiple)
  end

  # External source
  defp compile_source(map, :external, multiple, %{attributes: attrs} = el) do
    map
    |> maybe_put(:min_query_length, attrs[:min_query_length])
    |> put_initial_option_or_options(el, multiple)
  end

  # Users source
  defp compile_source(map, :users, multiple, %{attributes: attrs}) do
    if multiple do
      maybe_put(map, :initial_users, attrs[:initial_users])
    else
      maybe_put(map, :initial_user, attrs[:initial_user])
    end
  end

  # Conversations source
  defp compile_source(map, :conversations, multiple, %{attributes: attrs} = el) do
    map =
      if multiple do
        maybe_put(map, :initial_conversations, attrs[:initial_conversations])
      else
        maybe_put(map, :initial_conversation, attrs[:initial_conversation])
      end

    map
    |> maybe_put(:default_to_current_conversation, attrs[:default_to_current_conversation])
    |> maybe_put(:filter, compile_filter(el))
  end

  # Channels source
  defp compile_source(map, :channels, multiple, %{attributes: attrs}) do
    if multiple do
      maybe_put(map, :initial_channels, attrs[:initial_channels])
    else
      maybe_put(map, :initial_channel, attrs[:initial_channel])
    end
  end

  defp put_options_or_groups(map, %{children: %{option_groups: groups}}) when is_list(groups),
    do: Map.put(map, :option_groups, Enum.map(groups, &OptionGroup.compile/1))

  defp put_options_or_groups(map, %{children: %{options: options}}) when is_list(options),
    do: Map.put(map, :options, Enum.map(options, &Option.compile/1))

  defp put_options_or_groups(map, _), do: map

  defp put_initial_option_or_options(map, el, true = _multiple) do
    maybe_put(map, :initial_options, compile_initial_options(el))
  end

  defp put_initial_option_or_options(map, el, _multiple) do
    maybe_put(map, :initial_option, compile_initial_option(el))
  end

  defp compile_initial_option(%{children: %{initial_option: opt}}),
    do: Option.compile(opt)

  defp compile_initial_option(_), do: nil

  defp compile_initial_options(%{children: %{initial_options: opts}}) when is_list(opts),
    do: Enum.map(opts, &Option.compile/1)

  defp compile_initial_options(_), do: nil

  defp compile_filter(%{children: %{filter: filter}}),
    do: ConversationFilter.compile(filter)

  defp compile_filter(_), do: nil

  defp compile_confirm(%{children: %{confirm: confirm}}),
    do: ConfirmationDialog.compile(confirm)

  defp compile_confirm(_), do: nil
end
