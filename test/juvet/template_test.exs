defmodule Juvet.TemplateTest do
  use ExUnit.Case, async: true

  alias Juvet.Template

  import Juvet.Test.JsonHelpers, only: [json_equal?: 2]

  describe "render/1" do
    test "empty template returns empty string" do
      assert Template.render("") == ""
    end
  end

  describe "render/2" do
    # Skipping until EEx evaluation is supported
    @tag :skip
    test "simple evaluation within template returns evaluated string" do
      assert Template.render("<%= salutation %>", salutation: "Hello there") == "Hello there"
    end
  end

  describe "use Juvet.Template" do
    defmodule TestTemplates do
      use Juvet.Template

      template(:simple_header, ":slack.header{text: \"Hello\"}")
      template(:header_with_binding, ":slack.header{text: \"Hello <%= name %>\"}")

      template(:multi_element, """
      :slack.header{text: "Welcome <%= name %>"}
      :slack.divider
      """)
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

  describe "compile-time errors" do
    test "invalid template syntax raises CompileError" do
      assert_raise CompileError, ~r/template :bad has a syntax error/, fn ->
        Code.compile_string("""
        defmodule InvalidTemplate do
          use Juvet.Template
          template :bad, "invalid syntax @#\$%"
        end
        """)
      end
    end

    test "unknown element raises CompileError with line number" do
      assert_raise CompileError,
                   ~r/template :unknown failed to compile.*Unknown Slack element.*line 1/,
                   fn ->
                     Code.compile_string("""
                     defmodule UnknownElementTemplate do
                       use Juvet.Template
                       template :unknown, ":slack.nonexistent{text: \\"Hello\\"}"
                     end
                     """)
                   end
    end

    test "parser error includes line number" do
      assert_raise CompileError,
                   ~r/template :bad_parse has a parse error.*line 1/,
                   fn ->
                     Code.compile_string("""
                     defmodule BadParseTemplate do
                       use Juvet.Template
                       template :bad_parse, ":slack"
                     end
                     """)
                   end
    end
  end

  describe "template_file/2" do
    defmodule FileTemplates do
      use Juvet.Template

      template_file(:greeting, "templates/greeting.cheex")
    end

    test "loads and compiles template from file" do
      result = FileTemplates.greeting(name: "World")

      assert json_equal?(result, %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello World"}
                 },
                 %{"type" => "divider"}
               ]
             })
    end

    test "missing file raises CompileError" do
      assert_raise CompileError, ~r/template_file :missing could not read/, fn ->
        Code.compile_string("""
        defmodule MissingFileTemplate do
          use Juvet.Template
          template_file :missing, "nonexistent.cheex"
        end
        """)
      end
    end
  end

  describe "multiple templates per module" do
    defmodule MixedTemplates do
      use Juvet.Template

      # Inline templates
      template(:header, ":slack.header{text: \"Welcome\"}")
      template(:dynamic_section, ":slack.section{text: \"Hello <%= name %>\"}")

      # File-based templates
      template_file(:greeting, "templates/greeting.cheex")
      template_file(:static_divider, "templates/static.cheex")
    end

    test "inline static template works" do
      result = MixedTemplates.header()

      assert json_equal?(result, %{
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Welcome"}}
               ]
             })
    end

    test "inline dynamic template works" do
      result = MixedTemplates.dynamic_section(name: "World")

      assert json_equal?(result, %{
               "blocks" => [
                 %{"type" => "section", "text" => %{"type" => "mrkdwn", "text" => "Hello World"}}
               ]
             })
    end

    test "file-based dynamic template works" do
      result = MixedTemplates.greeting(name: "Alice")

      assert json_equal?(result, %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello Alice"}
                 },
                 %{"type" => "divider"}
               ]
             })
    end

    test "file-based static template works" do
      result = MixedTemplates.static_divider()

      assert json_equal?(result, %{"blocks" => [%{"type" => "divider"}]})
    end

    test "all templates in module are independent" do
      # Verify each template produces correct output independently
      header = MixedTemplates.header()
      section = MixedTemplates.dynamic_section(name: "Test")
      greeting = MixedTemplates.greeting(name: "Bob")
      divider = MixedTemplates.static_divider()

      # Each should be valid JSON with blocks
      assert %{"blocks" => [%{"type" => "header"} | _]} = Poison.decode!(header)
      assert %{"blocks" => [%{"type" => "section"} | _]} = Poison.decode!(section)

      assert %{"blocks" => [%{"type" => "header"}, %{"type" => "divider"}]} =
               Poison.decode!(greeting)

      assert %{"blocks" => [%{"type" => "divider"}]} = Poison.decode!(divider)
    end

    test "__templates__/0 returns list of template names" do
      assert MixedTemplates.__templates__() == [
               :header,
               :dynamic_section,
               :greeting,
               :static_divider
             ]
    end

    test "__template_ast__/1 returns AST for a template" do
      ast = MixedTemplates.__template_ast__(:header)

      assert [%{platform: :slack, element: :header, attributes: %{text: "Welcome"}} | _] = ast
    end

    test "__template_ast__/1 raises for unknown template" do
      assert_raise ArgumentError, ~r/template :unknown not found/, fn ->
        MixedTemplates.__template_ast__(:unknown)
      end
    end
  end

  describe "template partials" do
    defmodule PartialTemplates do
      use Juvet.Template

      # Define partial first (must come before templates that use it)
      template(:user_header, ":slack.header{text: \"Hello <%= name %>\"}")

      # Template using the partial with static binding
      template(:static_dashboard, """
      :slack.partial{template: :user_header, name: "Alice"}
      :slack.divider
      """)

      # Template using the partial with dynamic binding
      template(:dynamic_dashboard, """
      :slack.partial{template: :user_header, name: "<%= user_name %>"}
      :slack.divider
      """)
    end

    test "partial with static binding inlines the referenced template" do
      result = PartialTemplates.static_dashboard()

      assert %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello Alice"}
                 },
                 %{"type" => "divider"}
               ]
             } = Poison.decode!(result)
    end

    test "partial with dynamic binding passes through EEx" do
      result = PartialTemplates.dynamic_dashboard(user_name: "Bob")

      assert %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello Bob"}
                 },
                 %{"type" => "divider"}
               ]
             } = Poison.decode!(result)
    end

    test "partial can be used standalone" do
      result = PartialTemplates.user_header(name: "World")

      assert %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello World"}
                 }
               ]
             } = Poison.decode!(result)
    end
  end

  describe "nested partials" do
    defmodule NestedPartialTemplates do
      use Juvet.Template

      template(:greeting, ":slack.header{text: \"Hello <%= name %>\"}")

      template(:greeting_with_divider, """
      :slack.partial{template: :greeting, name: "<%= name %>"}
      :slack.divider
      """)

      template(:full_page, """
      :slack.partial{template: :greeting_with_divider, name: "<%= user %>"}
      :slack.section "Content"
      """)
    end

    test "nested partials are resolved recursively" do
      result = NestedPartialTemplates.full_page(user: "Alice")

      assert %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello Alice"}
                 },
                 %{"type" => "divider"},
                 %{"type" => "section"}
               ]
             } = Poison.decode!(result)
    end

    test "intermediate partial still works standalone" do
      result = NestedPartialTemplates.greeting_with_divider(name: "Bob")

      assert %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello Bob"}
                 },
                 %{"type" => "divider"}
               ]
             } = Poison.decode!(result)
    end
  end

  describe "view templates" do
    defmodule ViewTemplates do
      use Juvet.Template

      template(:simple_view, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Hello"}
          :slack.divider
      """)

      template(:view_with_metadata, """
      :slack.view
        type: :modal
        private_metadata: "some metadata"
        blocks:
          :slack.header{text: "Welcome"}
          :slack.section "Content here"
      """)

      template(:view_with_bindings, """
      :slack.view
        type: :modal
        private_metadata: "<%= metadata %>"
        blocks:
          :slack.header{text: "Hello <%= name %>"}
          :slack.divider
      """)

      template(:user_greeting, ":slack.header{text: \"Hello <%= name %>\"}")

      template(:view_with_partial, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :user_greeting, name: "<%= name %>"}
          :slack.divider
      """)
    end

    test "view with type and blocks" do
      result = ViewTemplates.simple_view()

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Hello"}},
                 %{"type" => "divider"}
               ]
             })
    end

    test "view with private_metadata" do
      result = ViewTemplates.view_with_metadata()

      assert json_equal?(result, %{
               "type" => "modal",
               "private_metadata" => "some metadata",
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Welcome"}
                 },
                 %{
                   "type" => "section",
                   "text" => %{"type" => "mrkdwn", "text" => "Content here"}
                 }
               ]
             })
    end

    test "view with EEx bindings" do
      result = ViewTemplates.view_with_bindings(name: "World", metadata: "user_123")

      assert json_equal?(result, %{
               "type" => "modal",
               "private_metadata" => "user_123",
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello World"}
                 },
                 %{"type" => "divider"}
               ]
             })
    end

    test "view with partial inside blocks" do
      result = ViewTemplates.view_with_partial(name: "Alice")

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello Alice"}
                 },
                 %{"type" => "divider"}
               ]
             })
    end
  end

  describe "partial error handling" do
    test "missing partial raises CompileError with line info" do
      assert_raise CompileError, ~r/partial :nonexistent not found \(line 1, column 1\)/, fn ->
        Code.compile_string("""
        defmodule MissingPartialTest do
          use Juvet.Template

          template :broken, \":slack.partial{template: :nonexistent}\"
        end
        """)
      end
    end

    test "missing template attribute raises CompileError" do
      assert_raise CompileError, ~r/partial is missing required template: attribute/, fn ->
        Code.compile_string("""
        defmodule MissingAttrPartialTest do
          use Juvet.Template

          template :broken, \":slack.partial{name: \\\"Alice\\\"}\"
        end
        """)
      end
    end

    test "circular partial reference raises CompileError" do
      # Create a contrived cycle: :a references :b, :b references :a
      cyclic_asts = %{
        a: [
          %{platform: :slack, element: :partial, attributes: %{template: :b}, line: 1, column: 1}
        ],
        b: [
          %{platform: :slack, element: :partial, attributes: %{template: :a}, line: 1, column: 1}
        ]
      }

      assert_raise CompileError, ~r/circular partial reference detected: a -> b -> a/, fn ->
        Juvet.Template.compile_template!(
          :test,
          ":slack.partial{template: :a}",
          cyclic_asts
        )
      end
    end
  end
end
