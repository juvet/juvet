defmodule Juvet.Template.ParserTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.{Parser, Tokenizer}

  defp parse(template) do
    template
    |> Tokenizer.tokenize()
    |> Parser.parse()
  end

  describe "parse/1 - Phase 1: Basic elements" do
    test "empty template returns empty list" do
      assert parse("") == []
    end

    test "simple element with no attributes" do
      assert parse(":slack.divider") == [
               %{platform: :slack, element: :divider, attributes: %{}}
             ]
    end

    test "element with different platform and type" do
      assert parse(":slack.header") == [
               %{platform: :slack, element: :header, attributes: %{}}
             ]
    end
  end
end
