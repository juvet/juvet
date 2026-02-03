defmodule Juvet.Template.Compiler.Slack.Elements.Image do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.SlackFile
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :image, attributes: attrs} = el) do
    %{type: "image"}
    |> maybe_put(:image_url, attrs[:url])
    |> maybe_put(:alt_text, attrs[:alt_text])
    |> maybe_put(:slack_file, compile_slack_file(el))
  end

  defp compile_slack_file(%{children: %{slack_file: slack_file}}),
    do: SlackFile.compile(slack_file)

  defp compile_slack_file(_), do: nil
end
