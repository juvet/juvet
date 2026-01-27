defmodule Juvet.TemplateTest do
  use ExUnit.Case, async: true

  alias Juvet.Template

  import Juvet.Test.JsonHelpers, only: [json_equal?: 2]

  describe "render/1" do
    # We are not here yet
    @tag :skip
    test "empty template returns empty string" do
      assert Template.render("") == ""
    end
  end

  describe "render/2" do
    # This may or may not be a valid case
    @tag :skip
    test "simple evaluation within template returns evaluated string" do
      assert Template.render("<%= salutation %>", salutation: "Hello there") == "Hello there"
    end
  end

  describe "use Juvet.Template" do
    defmodule TestTemplates do
      use Juvet.Template

      template :simple_header, ":slack.header{text: \"Hello\"}"
      template :header_with_binding, ":slack.header{text: \"Hello <%= name %>\"}"
      template :multi_element, """
      :slack.header{text: "Welcome <%= name %>"}
      :slack.divider
      """
    end

    test "compiles template and generates function" do
      result = TestTemplates.simple_header()

      assert json_equal?(result, %{
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Hello"}}
               ]
             })
    end

    test "generated function accepts bindings" do
      result = TestTemplates.header_with_binding(name: "World")

      assert json_equal?(result, %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello World"}
                 }
               ]
             })
    end

    test "bindings default to empty list" do
      result = TestTemplates.simple_header()
      assert is_binary(result)
    end

    test "multi-element template with bindings" do
      result = TestTemplates.multi_element(name: "Alice")

      assert json_equal?(result, %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Welcome Alice"}
                 },
                 %{"type" => "divider"}
               ]
             })
    end

    test "template without interpolation ignores bindings" do
      # Static templates don't use bindings, so passing any value works
      result1 = TestTemplates.simple_header()
      result2 = TestTemplates.simple_header(name: "ignored")

      assert result1 == result2
    end
  end
end
