defmodule Juvet.Template.Compiler.Slack.Blocks.Image do
  @moduledoc false

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :image, attributes: attrs}) do
    %{type: "image"}
    |> maybe_put(:image_url, attrs[:url])
    |> maybe_put(:alt_text, attrs[:alt_text])
  end
end
