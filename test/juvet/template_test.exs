defmodule Juvet.TemplateTest do
  use ExUnit.Case, async: true

  alias Juvet.Template

  import Juvet.Test.JsonHelpers, only: [json_equal?: 2]

  describe "render/1" do
    test "empty template returns empty map" do
      assert Template.render("") == %{}
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

      template(:simple_header, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Hello"}
      """)

      template(:header_with_binding, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Hello <%= name %>"}
      """)

      template(:multi_element, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Welcome <%= name %>"}
          :slack.divider
      """)
    end

    test "compiles template and generates function" do
      result = TestTemplates.simple_header()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello"}}
               ]
             }
    end

    test "generated function accepts bindings" do
      result = TestTemplates.header_with_binding(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello World"}
                 }
               ]
             }
    end

    test "bindings default to empty list" do
      result = TestTemplates.simple_header()
      assert is_map(result)
    end

    test "multi-element template with bindings" do
      result = TestTemplates.multi_element(name: "Alice")

      assert result == %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Welcome Alice"}
                 },
                 %{type: "divider"}
               ]
             }
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
                   ~r/template :unknown failed to compile.*Unknown Slack element.*line 4/,
                   fn ->
                     Code.compile_string("""
                     defmodule UnknownElementTemplate do
                       use Juvet.Template
                       template :unknown, \":slack.view\\n  type: :modal\\n  blocks:\\n    :slack.nonexistent{text: \\\"Hello\\\"}\"
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

  describe "template/2 with file: option" do
    defmodule FileTemplates do
      use Juvet.Template

      template(:greeting, file: "templates/greeting.cheex")
    end

    test "loads and compiles template from file" do
      result = FileTemplates.greeting(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello World"}
                 },
                 %{type: "divider"}
               ]
             }
    end

    test "missing file raises CompileError" do
      assert_raise CompileError, ~r/template :missing could not read/, fn ->
        Code.compile_string("""
        defmodule MissingFileTemplate do
          use Juvet.Template
          template :missing, file: "nonexistent.cheex"
        end
        """)
      end
    end
  end

  describe "multiple templates per module" do
    defmodule MixedTemplates do
      use Juvet.Template

      # Inline templates
      template(:header, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Welcome"}
      """)

      template(:dynamic_section, """
      :slack.view
        type: :modal
        blocks:
          :slack.section{text: "Hello <%= name %>"}
      """)

      # File-based templates
      template(:greeting, file: "templates/greeting.cheex")
      template(:static_divider, file: "templates/static.cheex")
    end

    test "inline static template works" do
      result = MixedTemplates.header()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Welcome"}}
               ]
             }
    end

    test "inline dynamic template works" do
      result = MixedTemplates.dynamic_section(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "Hello World"}}
               ]
             }
    end

    test "file-based dynamic template works" do
      result = MixedTemplates.greeting(name: "Alice")

      assert result == %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello Alice"}
                 },
                 %{type: "divider"}
               ]
             }
    end

    test "file-based static template works" do
      result = MixedTemplates.static_divider()

      assert result == %{
               type: "modal",
               blocks: [%{type: "divider"}]
             }
    end

    test "all templates in module are independent" do
      # Verify each template produces correct output independently
      header = MixedTemplates.header()
      section = MixedTemplates.dynamic_section(name: "Test")
      greeting = MixedTemplates.greeting(name: "Bob")
      divider = MixedTemplates.static_divider()

      # Each should be a map with type and blocks
      assert %{type: "modal", blocks: [%{type: "header"} | _]} = header
      assert %{type: "modal", blocks: [%{type: "section"} | _]} = section
      assert %{type: "modal", blocks: [%{type: "header"}, %{type: "divider"}]} = greeting
      assert %{type: "modal", blocks: [%{type: "divider"}]} = divider
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

      assert [%{platform: :slack, element: :view, attributes: %{type: :modal}} | _] = ast
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
      partial(:user_header, ":slack.header{text: \"Hello <%= name %>\"}")

      # Template using the partial with static binding
      template(:static_dashboard, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :user_header, name: "Alice"}
          :slack.divider
      """)

      # Template using the partial with dynamic binding
      template(:dynamic_dashboard, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :user_header, name: "<%= user_name %>"}
          :slack.divider
      """)
    end

    test "partial with static binding inlines the referenced template" do
      result = PartialTemplates.static_dashboard()

      assert %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello Alice"}
                 },
                 %{type: "divider"}
               ]
             } = result
    end

    test "partial with dynamic binding passes through EEx" do
      result = PartialTemplates.dynamic_dashboard(user_name: "Bob")

      assert %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello Bob"}
                 },
                 %{type: "divider"}
               ]
             } = result
    end

    test "partials do not appear in __templates__ list" do
      refute :user_header in PartialTemplates.__templates__()
    end

    test "partial AST is available via __template_ast__" do
      ast = PartialTemplates.__template_ast__(:user_header)

      assert [%{platform: :slack, element: :header, attributes: %{text: "Hello <%= name %>"}}] =
               ast
    end
  end

  describe "nested partials" do
    defmodule NestedPartialTemplates do
      use Juvet.Template

      partial(:greeting, ":slack.header{text: \"Hello <%= name %>\"}")

      template(:greeting_with_divider, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :greeting, name: "<%= name %>"}
          :slack.divider
      """)

      template(:full_page, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :greeting, name: "<%= user %>"}
          :slack.divider
          :slack.section "Content"
      """)
    end

    test "nested partials are resolved recursively" do
      result = NestedPartialTemplates.full_page(user: "Alice")

      assert %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello Alice"}
                 },
                 %{type: "divider"},
                 %{type: "section"}
               ]
             } = result
    end

    test "template using partial works" do
      result = NestedPartialTemplates.greeting_with_divider(name: "Bob")

      assert %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello Bob"}
                 },
                 %{type: "divider"}
               ]
             } = result
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

      partial(:user_greeting, ":slack.header{text: \"Hello <%= name %>\"}")

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

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello"}},
                 %{type: "divider"}
               ]
             }
    end

    test "view with private_metadata" do
      result = ViewTemplates.view_with_metadata()

      assert result == %{
               type: "modal",
               private_metadata: "some metadata",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Welcome"}
                 },
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Content here"}
                 }
               ]
             }
    end

    test "view with EEx bindings" do
      result = ViewTemplates.view_with_bindings(name: "World", metadata: "user_123")

      assert result == %{
               type: "modal",
               private_metadata: "user_123",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello World"}
                 },
                 %{type: "divider"}
               ]
             }
    end

    test "view with partial inside blocks" do
      result = ViewTemplates.view_with_partial(name: "Alice")

      assert result == %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello Alice"}
                 },
                 %{type: "divider"}
               ]
             }
    end
  end

  describe "platform inheritance shorthand" do
    defmodule ShorthandTemplates do
      use Juvet.Template

      template(:shorthand_view, """
      :slack.view
        type: :modal
        blocks:
          .header{text: "Hello"}
          .divider
          .section "Welcome"
      """)

      template(:shorthand_with_bindings, """
      :slack.view
        type: :modal
        blocks:
          .header{text: "Hello <%= name %>"}
          .divider
      """)

      template(:mixed_syntax, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Full"}
          .divider
          .section "Short"
      """)
    end

    test "shorthand elements compile to correct output" do
      result = ShorthandTemplates.shorthand_view()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello"}},
                 %{type: "divider"},
                 %{type: "section", text: %{type: "mrkdwn", text: "Welcome"}}
               ]
             }
    end

    test "shorthand elements with bindings" do
      result = ShorthandTemplates.shorthand_with_bindings(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello World"}},
                 %{type: "divider"}
               ]
             }
    end

    test "mixed full and shorthand syntax produces identical output" do
      result = ShorthandTemplates.mixed_syntax()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Full"}},
                 %{type: "divider"},
                 %{type: "section", text: %{type: "mrkdwn", text: "Short"}}
               ]
             }
    end
  end

  describe "file-based partials" do
    defmodule FilePartialTemplates do
      use Juvet.Template

      partial(:user_header, file: "templates/user_header.cheex")

      template(:dashboard, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :user_header, name: "<%= name %>"}
          :slack.divider
      """)
    end

    test "file-based partial is inlined into view template" do
      result = FilePartialTemplates.dashboard(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello World"}
                 },
                 %{type: "divider"}
               ]
             }
    end

    test "file-based partial does not appear in __templates__ list" do
      refute :user_header in FilePartialTemplates.__templates__()
    end

    test "file-based partial AST is available via __template_ast__" do
      ast = FilePartialTemplates.__template_ast__(:user_header)

      assert [%{platform: :slack, element: :header, attributes: %{text: "Hello <%= name %>"}}] =
               ast
    end

    test "missing partial file raises CompileError" do
      assert_raise CompileError, ~r/partial :missing could not read/, fn ->
        Code.compile_string("""
        defmodule MissingFilePartial do
          use Juvet.Template
          partial :missing, file: "nonexistent.cheex"
        end
        """)
      end
    end
  end

  describe "partial error handling" do
    test "missing partial raises CompileError with line info" do
      assert_raise CompileError, ~r/partial :nonexistent not found \(line 4, column 5\)/, fn ->
        Code.compile_string("""
        defmodule MissingPartialTest do
          use Juvet.Template

          template :broken, \":slack.view\\n  type: :modal\\n  blocks:\\n    :slack.partial{template: :nonexistent}\"
        end
        """)
      end
    end

    test "missing template attribute raises CompileError" do
      assert_raise CompileError, ~r/partial is missing required template: attribute/, fn ->
        Code.compile_string("""
        defmodule MissingAttrPartialTest do
          use Juvet.Template

          template :broken, \":slack.view\\n  type: :modal\\n  blocks:\\n    :slack.partial{name: \\\"Alice\\\"}\"
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
          ":slack.view\n  type: :modal\n  blocks:\n    :slack.partial{template: :a}",
          cyclic_asts
        )
      end
    end
  end

  describe "format: :json option" do
    defmodule JsonTemplates do
      use Juvet.Template, format: :json

      template(:static_header, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Hello"}
      """)

      template(:dynamic_header, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Hello <%= name %>"}
      """)
    end

    test "module-level format: :json returns JSON string for static template" do
      result = JsonTemplates.static_header()

      assert is_binary(result)

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Hello"}}
               ]
             })
    end

    test "module-level format: :json returns JSON string for dynamic template" do
      result = JsonTemplates.dynamic_header(name: "World")

      assert is_binary(result)

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello World"}
                 }
               ]
             })
    end
  end

  describe "per-template format override" do
    defmodule MixedFormatTemplates do
      use Juvet.Template

      template(:map_header, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Hello"}
      """)

      template(
        :json_header,
        """
        :slack.view
          type: :modal
          blocks:
            :slack.header{text: "Hello"}
        """,
        format: :json
      )

      template(
        :json_dynamic,
        """
        :slack.view
          type: :modal
          blocks:
            :slack.header{text: "Hello <%= name %>"}
        """,
        format: :json
      )
    end

    test "default format returns map" do
      result = MixedFormatTemplates.map_header()
      assert is_map(result)
      assert result[:type] == "modal"
    end

    test "per-template format: :json returns JSON string" do
      result = MixedFormatTemplates.json_header()
      assert is_binary(result)

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Hello"}}
               ]
             })
    end

    test "per-template format: :json with bindings returns JSON string" do
      result = MixedFormatTemplates.json_dynamic(name: "World")
      assert is_binary(result)

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello World"}
                 }
               ]
             })
    end
  end

  describe ".slack.cheex file-based templates" do
    defmodule SlackFileTemplates do
      use Juvet.Template

      partial(:shorthand_header, file: "templates/shorthand_partial.slack.cheex")

      template(:home, file: "templates/home.slack.cheex")

      template(:with_partial, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :shorthand_header, name: "<%= name %>"}
          :slack.divider
      """)
    end

    test "file template with shorthand compiles correctly" do
      result = SlackFileTemplates.home(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello World"}},
                 %{type: "divider"},
                 %{type: "section", text: %{type: "mrkdwn", text: "Welcome"}}
               ]
             }
    end

    test "file partial with shorthand works in a view" do
      result = SlackFileTemplates.with_partial(name: "Alice")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello Alice"}},
                 %{type: "divider"}
               ]
             }
    end

    test "template with matching :slack.element in .slack.cheex is allowed" do
      # Using full :slack.element syntax in a .slack.cheex file is allowed (just redundant)
      {ast, _compiled} =
        Template.compile_template!(
          :matching,
          ":slack.view\n  type: :modal\n  blocks:\n    :slack.header{text: \"Hello\"}",
          [],
          platform: :slack
        )

      assert [%{platform: :slack, element: :view}] = ast
    end

    test "template with mismatching platform in .slack.cheex raises CompileError" do
      assert_raise CompileError,
                   ~r/platform :discord in template does not match expected platform :slack/,
                   fn ->
                     Template.compile_template!(
                       :bad,
                       ":discord.header{text: \"Hello\"}",
                       [],
                       platform: :slack
                     )
                   end
    end

    test "regular .cheex files continue to work as before" do
      result = SlackFileTemplates.__template_ast__(:home)
      assert [%{platform: :slack, element: :view} | _] = result
    end
  end

  describe "file-based template with format override" do
    defmodule FileFormatTemplates do
      use Juvet.Template

      template(:greeting_map, file: "templates/greeting.cheex")
      template(:greeting_json, file: "templates/greeting.cheex", format: :json)
    end

    test "file template defaults to map format" do
      result = FileFormatTemplates.greeting_map(name: "World")
      assert is_map(result)
      assert result[:type] == "modal"
    end

    test "file template with format: :json returns JSON" do
      result = FileFormatTemplates.greeting_json(name: "World")
      assert is_binary(result)

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello World"}
                 },
                 %{"type" => "divider"}
               ]
             })
    end
  end

  describe "for-loop support" do
    defmodule ForLoopTemplates do
      use Juvet.Template

      template(:simple_loop, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Decisions"}
          <%= for decision <- decisions do %>
          .section{text: "<%= decision %>", type: :mrkdwn}
          <% end %>
          :slack.divider
      """)

      template(:empty_collection, """
      :slack.view
        type: :modal
        blocks:
          :slack.header{text: "Title"}
          <%= for item <- items do %>
          .section{text: "<%= item %>"}
          <% end %>
      """)

      template(:loop_with_multiple_body, """
      :slack.view
        type: :modal
        blocks:
          <%= for item <- items do %>
          .header{text: "<%= item %>"}
          .divider
          <% end %>
      """)

      template(:loop_only, """
      :slack.view
        type: :modal
        blocks:
          <%= for item <- items do %>
          .section{text: "<%= item %>"}
          <% end %>
      """)
    end

    test "for-loop with bindings produces correct expanded output" do
      result = ForLoopTemplates.simple_loop(decisions: ["Option A", "Option B"])

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Decisions"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "Option A"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "Option B"}},
                 %{type: "divider"}
               ]
             }
    end

    test "empty collection produces zero loop elements" do
      result = ForLoopTemplates.empty_collection(items: [])

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Title"}}
               ]
             }
    end

    test "for-loop alongside static elements" do
      result = ForLoopTemplates.simple_loop(decisions: ["Only One"])

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Decisions"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "Only One"}},
                 %{type: "divider"}
               ]
             }
    end

    test "for-loop with multiple body elements" do
      result = ForLoopTemplates.loop_with_multiple_body(items: ["A", "B"])

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "A"}},
                 %{type: "divider"},
                 %{type: "header", text: %{type: "plain_text", text: "B"}},
                 %{type: "divider"}
               ]
             }
    end

    test "for-loop as only blocks content" do
      result = ForLoopTemplates.loop_only(items: ["X", "Y"])

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "X"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "Y"}}
               ]
             }
    end
  end

  describe "for-loop inside element children" do
    defmodule ForLoopInElementChildrenTemplates do
      use Juvet.Template

      template(:overflow_with_loop, """
      :slack.view
        type: :home
        blocks:
          .section
            text: "Pick an action"
            type: :mrkdwn
            accessory:
              .overflow
                options:
                  <%= for action <- actions do %>
                  .option{text: "<%= action.text %>", value: "<%= action.value %>", emoji: true}
                  <% end %>
      """)
    end

    test "for-loop inside overflow options renders dynamic options" do
      actions = [
        %{text: ":pencil2:  Edit", value: "1"},
        %{text: ":wastebasket:  Delete", value: "1"}
      ]

      result = ForLoopInElementChildrenTemplates.overflow_with_loop(actions: actions)

      assert result == %{
               type: "home",
               blocks: [
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Pick an action"},
                   accessory: %{
                     type: "overflow",
                     options: [
                       %{
                         text: %{type: "plain_text", text: ":pencil2:  Edit", emoji: true},
                         value: "1"
                       },
                       %{
                         text: %{type: "plain_text", text: ":wastebasket:  Delete", emoji: true},
                         value: "1"
                       }
                     ]
                   }
                 }
               ]
             }
    end
  end

  describe "for-loop with JSON format" do
    defmodule ForLoopJsonTemplates do
      use Juvet.Template, format: :json

      template(:json_loop, """
      :slack.view
        type: :modal
        blocks:
          <%= for item <- items do %>
          .section{text: "<%= item %>"}
          <% end %>
      """)
    end

    test "for-loop produces correct JSON output" do
      result = ForLoopJsonTemplates.json_loop(items: ["Hello", "World"])
      assert is_binary(result)

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{"type" => "section", "text" => %{"type" => "mrkdwn", "text" => "Hello"}},
                 %{"type" => "section", "text" => %{"type" => "mrkdwn", "text" => "World"}}
               ]
             })
    end
  end

  describe "string interpolation" do
    defmodule InterpolationTemplates do
      use Juvet.Template

      template(:greeting,
        slack: ".view\n  type: :modal\n  blocks:\n    .header{text: \"Hello \#{name}\"}"
      )

      template(:loop_with_interpolation,
        slack:
          ".view\n  type: :modal\n  blocks:\n    <%= for item <- items do %>\n    .section{text: \"\#{item}\"}\n    <% end %>"
      )
    end

    test "string interpolation with bindings renders correctly" do
      result = InterpolationTemplates.greeting(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello World"}}
               ]
             }
    end

    test "string interpolation inside for-loop body works" do
      result = InterpolationTemplates.loop_with_interpolation(items: ["Alpha", "Beta"])

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "Alpha"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "Beta"}}
               ]
             }
    end
  end

  describe "code block support" do
    defmodule CodeBlockTemplates do
      use Juvet.Template

      template(:code_block_simple, """
      :slack.view
        type: :modal
        blocks:
          <% x = 1 %>
          .section{text: "<%= x %>", type: :mrkdwn}
      """)

      template(:sequential_code_blocks, """
      :slack.view
        type: :modal
        blocks:
          <% x = 1 %>
          <% y = x + 1 %>
          .section{text: "<%= y %>", type: :mrkdwn}
      """)

      template(:code_block_with_bindings, """
      :slack.view
        type: :modal
        blocks:
          <% result = String.upcase(name) %>
          .section{text: "<%= result %>", type: :mrkdwn}
      """)

      template(:code_block_in_loop, """
      :slack.view
        type: :modal
        blocks:
          <%= for item <- items do %>
          <% upper = String.upcase(item) %>
          .section{text: "<%= upper %>", type: :mrkdwn}
          <% end %>
      """)

      template(:code_block_with_static_before, """
      :slack.view
        type: :modal
        blocks:
          .header{text: "Title"}
          <% x = 1 %>
          .section{text: "<%= x %>", type: :mrkdwn}
          .divider
      """)
    end

    test "simple code block defines variable for subsequent elements" do
      result = CodeBlockTemplates.code_block_simple()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "1"}}
               ]
             }
    end

    test "sequential code blocks can reference previous variables" do
      result = CodeBlockTemplates.sequential_code_blocks()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "2"}}
               ]
             }
    end

    test "code block can use bindings passed to template" do
      result = CodeBlockTemplates.code_block_with_bindings(name: "hello")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "HELLO"}}
               ]
             }
    end

    test "code block inside for-loop body with per-iteration scope" do
      result = CodeBlockTemplates.code_block_in_loop(items: ["hello", "world"])

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "HELLO"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "WORLD"}}
               ]
             }
    end

    test "code block mixed with static elements" do
      result = CodeBlockTemplates.code_block_with_static_before()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Title"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "1"}},
                 %{type: "divider"}
               ]
             }
    end

    test "error in code block raises with line/column context" do
      assert_raise RuntimeError, ~r/Error in code block at line .*, column .*/, fn ->
        Code.eval_string("""
        defmodule CodeBlockErrorTemplate do
          use Juvet.Template

          template(:bad_code_block, \"\"\"
          :slack.view
            type: :modal
            blocks:
              <% result = nonexistent_function() %>
              .section{text: "<%= result %>", type: :mrkdwn}
          \"\"\")
        end

        CodeBlockErrorTemplate.bad_code_block()
        """)
      end
    end

    test "existing for-loop templates still work" do
      alias Juvet.TemplateTest.ForLoopTemplates
      result = ForLoopTemplates.simple_loop(decisions: ["A", "B"])

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Decisions"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "A"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "B"}},
                 %{type: "divider"}
               ]
             }
    end
  end

  describe "inline platform keyword syntax" do
    defmodule InlinePlatformTemplates do
      use Juvet.Template

      template(:slack_shorthand,
        slack: ".view\n  type: :modal\n  blocks:\n    .header{text: \"Hello\"}\n    .divider"
      )

      template(:slack_with_bindings,
        slack:
          ".view\n  type: :modal\n  blocks:\n    .header{text: \"Hello <%= name %>\"}\n    .divider"
      )

      template(:slack_with_json,
        slack: ".view\n  type: :modal\n  blocks:\n    .header{text: \"Hello\"}",
        format: :json
      )

      template(:inline_keyword,
        inline:
          ":slack.view\n  type: :modal\n  blocks:\n    :slack.header{text: \"Hello\"}\n    :slack.divider"
      )

      template(:slack_redundant_full_syntax,
        slack:
          ":slack.view\n  type: :modal\n  blocks:\n    :slack.header{text: \"Redundant\"}\n    .divider"
      )

      partial(:slack_partial_header, slack: ".header{text: \"Hello <%= name %>\"}")

      partial(:inline_partial_header, inline: ":slack.header{text: \"Hello <%= name %>\"}")

      template(:using_slack_partial, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :slack_partial_header, name: "<%= name %>"}
          :slack.divider
      """)

      template(:using_inline_partial, """
      :slack.view
        type: :modal
        blocks:
          :slack.partial{template: :inline_partial_header, name: "<%= name %>"}
          :slack.divider
      """)
    end

    test "slack: keyword compiles view with all-shorthand elements" do
      result = InlinePlatformTemplates.slack_shorthand()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello"}},
                 %{type: "divider"}
               ]
             }
    end

    test "slack: keyword with EEx bindings" do
      result = InlinePlatformTemplates.slack_with_bindings(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello World"}},
                 %{type: "divider"}
               ]
             }
    end

    test "slack: keyword with format: :json override" do
      result = InlinePlatformTemplates.slack_with_json()
      assert is_binary(result)

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Hello"}}
               ]
             })
    end

    test "inline: keyword works like bare string source" do
      result = InlinePlatformTemplates.inline_keyword()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello"}},
                 %{type: "divider"}
               ]
             }
    end

    test "slack: keyword with matching :slack.element is allowed (redundant)" do
      result = InlinePlatformTemplates.slack_redundant_full_syntax()

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Redundant"}},
                 %{type: "divider"}
               ]
             }
    end

    test "slack: keyword with mismatching :discord.element raises CompileError" do
      assert_raise CompileError,
                   ~r/platform :discord in template does not match expected platform :slack/,
                   fn ->
                     Code.compile_string("""
                     defmodule MismatchInlinePlatform do
                       use Juvet.Template
                       template :bad, slack: ":discord.header{text: \\"Hello\\"}"
                     end
                     """)
                   end
    end

    test "partial with slack: keyword works and can be referenced by templates" do
      result = InlinePlatformTemplates.using_slack_partial(name: "Alice")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello Alice"}},
                 %{type: "divider"}
               ]
             }
    end

    test "partial with inline: keyword works" do
      result = InlinePlatformTemplates.using_inline_partial(name: "Bob")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello Bob"}},
                 %{type: "divider"}
               ]
             }
    end
  end

  describe "template helpers" do
    alias Juvet.TemplateTest.TestTemplates

    defmodule TestHelpers.Greeter do
      def greet(name), do: "Hello, #{name}!"
    end

    defmodule TestHelpers.Formatter do
      def format_text(text), do: String.upcase(text)
      def format_text(text, style) when style == :bold, do: "*#{text}*"
    end

    defmodule TestHelpers.ConflictA do
      def conflicting_fn(x), do: "A: #{x}"
    end

    defmodule TestHelpers.ConflictB do
      def conflicting_fn(x), do: "B: #{x}"
    end

    defmodule HelperTemplates do
      use Juvet.Template, helpers: [Juvet.TemplateTest.TestHelpers.Greeter]

      template(:with_helper, """
      :slack.view
        type: :modal
        blocks:
          :slack.section{text: "<%= greet.(name) %>", type: :mrkdwn}
      """)
    end

    test "helper module function available as binding via dot-call" do
      result = HelperTemplates.with_helper(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "Hello, World!"}}
               ]
             }
    end

    test "conflicting function names across helpers raises compile-time error" do
      assert_raise CompileError, ~r/Helper conflict/, fn ->
        Code.compile_string("""
        defmodule ConflictingHelperTemplate do
          use Juvet.Template, helpers: [
            Juvet.TemplateTest.TestHelpers.ConflictA,
            Juvet.TemplateTest.TestHelpers.ConflictB
          ]

          template :test, \":slack.view\\n  type: :modal\\n  blocks:\\n    :slack.section{text: \\\"<%= conflicting_fn.(\\\\\\\"x\\\\\\\") %>\\\"}\"
        end
        """)
      end
    end

    test "user bindings override helper bindings" do
      custom_greet = fn _name -> "Custom greeting!" end
      result = HelperTemplates.with_helper(name: "World", greet: custom_greet)

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "Custom greeting!"}}
               ]
             }
    end

    defmodule MultiHelperTemplates do
      use Juvet.Template,
        helpers: [
          Juvet.TemplateTest.TestHelpers.Greeter,
          Juvet.TemplateTest.TestHelpers.Formatter
        ]

      template(:with_multiple_helpers, """
      :slack.view
        type: :modal
        blocks:
          :slack.section{text: "<%= greet.(name) %>", type: :mrkdwn}
          :slack.section{text: "<%= format_text.(label, :bold) %>", type: :mrkdwn}
      """)
    end

    test "multiple helper modules make all functions available" do
      result = MultiHelperTemplates.with_multiple_helpers(name: "World", label: "hello")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "Hello, World!"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "*hello*"}}
               ]
             }
    end

    defmodule MultiArityHelperTemplates do
      use Juvet.Template, helpers: [Juvet.TemplateTest.TestHelpers.Formatter]

      template(:with_multi_arity, """
      :slack.view
        type: :modal
        blocks:
          :slack.section{text: "<%= format_text.(label, :bold) %>", type: :mrkdwn}
      """)
    end

    test "highest arity capture is used for multi-arity functions" do
      result = MultiArityHelperTemplates.with_multi_arity(label: "hello")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "*hello*"}}
               ]
             }
    end

    defmodule HelperJsonTemplates do
      use Juvet.Template, format: :json, helpers: [Juvet.TemplateTest.TestHelpers.Greeter]

      template(:json_with_helper, """
      :slack.view
        type: :modal
        blocks:
          :slack.section{text: "<%= greet.(name) %>", type: :mrkdwn}
      """)
    end

    test "helpers work with JSON format" do
      result = HelperJsonTemplates.json_with_helper(name: "World")
      assert is_binary(result)

      assert json_equal?(result, %{
               "type" => "modal",
               "blocks" => [
                 %{
                   "type" => "section",
                   "text" => %{"type" => "mrkdwn", "text" => "Hello, World!"}
                 }
               ]
             })
    end

    test "templates without helpers still work (regression)" do
      result = TestTemplates.header_with_binding(name: "World")

      assert result == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello World"}}
               ]
             }
    end
  end

  describe "multiple EEx expressions in attribute values" do
    defmodule MultipleEExTemplates do
      use Juvet.Template

      template(:multiple_eex_in_value,
        slack:
          ".view\n  type: :modal\n  blocks:\n    .actions\n      elements:\n        .button{text: \"Click\", action_id: \"btn\"}\n        .select\n          source: :static\n          action_id: \"test\"\n          placeholder: \"Pick...\"\n          options:\n            <%= for item <- items do %>\n              .option{text: \"<%= item.name %>\", value: \"<%= item.prefix %>_<%= item.id %>\"}\n            <% end %>"
      )
    end

    test "multiple EEx expressions in a single attribute value render correctly" do
      # This also makes sure `_` is handled within the EEx expression
      result =
        MultipleEExTemplates.multiple_eex_in_value(
          items: [
            %{name: "Task One", prefix: "tasks", id: 42},
            %{name: "Poll Two", prefix: "polls", id: 7}
          ]
        )

      select = result.blocks |> hd() |> Map.get(:elements) |> List.last()

      assert select.options == [
               %{text: %{type: "plain_text", text: "Task One"}, value: "tasks_42"},
               %{text: %{type: "plain_text", text: "Poll Two"}, value: "polls_7"}
             ]
    end
  end

  describe "function calls in for-loop collections" do
    defmodule ForLoopHelpers do
      def group_items(items) do
        items
        |> Enum.group_by(& &1.type)
        |> Enum.map(fn {type, group} -> %{label: type, items: group} end)
      end
    end

    defmodule ForLoopFunctionCallTemplates do
      use Juvet.Template, helpers: [Juvet.TemplateTest.ForLoopHelpers]

      template(:with_helper_call,
        slack:
          ".view\n  type: :modal\n  blocks:\n    <%= for group <- group_items.(items) do %>\n      .section{text: \"<%= group.label %>\", type: :mrkdwn}\n    <% end %>"
      )

      template(:with_inline_call,
        slack:
          ".view\n  type: :modal\n  blocks:\n    <%= for group <- Enum.chunk_every(items, 2) do %>\n      .section{text: \"<%= length(group) %>\", type: :mrkdwn}\n    <% end %>"
      )
    end

    test "for-loop collection can be a helper function call" do
      result =
        ForLoopFunctionCallTemplates.with_helper_call(
          items: [
            %{type: "Tasks", name: "T1"},
            %{type: "Tasks", name: "T2"},
            %{type: "Polls", name: "P1"}
          ]
        )

      labels = Enum.map(result.blocks, & &1.text.text) |> Enum.sort()
      assert labels == ["Polls", "Tasks"]
    end

    test "for-loop collection can be an inline Elixir expression" do
      result = ForLoopFunctionCallTemplates.with_inline_call(items: [1, 2, 3, 4, 5])

      assert result.blocks == [
               %{type: "section", text: %{type: "mrkdwn", text: "2"}},
               %{type: "section", text: %{type: "mrkdwn", text: "2"}},
               %{type: "section", text: %{type: "mrkdwn", text: "1"}}
             ]
    end
  end
end
