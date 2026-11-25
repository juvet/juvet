defmodule Juvet.Template.CompilerTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.{Compiler, Parser, Tokenizer}

  describe "compile/1" do
    test "empty AST returns empty map" do
      assert Compiler.compile([]) == %{}
    end

    test "delegates slack elements to Slack compiler" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal},
          children: %{
            blocks: [%{platform: :slack, element: :divider, attributes: %{}}]
          }
        }
      ]

      result = Compiler.compile(ast)

      assert result[:type] == "modal"
      assert result[:blocks] == [%{type: "divider"}]
    end
  end

  describe "compile/1 with a lone option" do
    defp compile_source(source),
      do:
        source
        |> Tokenizer.tokenize()
        |> Parser.parse()
        |> Compiler.compile()

    defp accessory(source), do: compile_source(source)[:blocks] |> hd() |> Map.fetch!(:accessory)

    test "keeps the only option of an option group" do
      select =
        accessory("""
        :slack.view
          type: :home
          blocks:
            .section
              text: "x"
              accessory:
                .select
                  source: :static
                  action_id: "a"
                  option_groups:
                    .option_group{label: "Only"}
                      options:
                        .option{text: "A", value: "a"}
        """)

      assert [%{label: %{text: "Only"}, options: [%{value: "a"}]}] = select[:option_groups]
    end

    test "keeps the only option of a select and an overflow" do
      select =
        accessory("""
        :slack.view
          type: :home
          blocks:
            .section
              text: "x"
              accessory:
                .select
                  source: :static
                  action_id: "a"
                  options:
                    .option{text: "A", value: "a"}
        """)

      overflow =
        accessory("""
        :slack.view
          type: :home
          blocks:
            .section
              text: "x"
              accessory:
                .overflow{action_id: "o"}
                  options:
                    .option{text: "A", value: "a"}
        """)

      assert [%{value: "a"}] = select[:options]
      assert [%{value: "a"}] = overflow[:options]
    end
  end

  describe "compile/1 with a rich text input" do
    defp rich_text_input(initial_value) do
      compile_source("""
      :slack.view
        type: :home
        blocks:
          .actions
            elements:
              .rich_text_input
                action_id: "search"
                initial_value: "#{initial_value}"
      """)[:blocks]
      |> hd()
      |> Map.fetch!(:elements)
      |> hd()
    end

    test "wraps plain initial text in the rich text Slack expects" do
      assert rich_text_input("deck acme")[:initial_value] == %{
               type: "rich_text",
               elements: [
                 %{type: "rich_text_section", elements: [%{type: "text", text: "deck acme"}]}
               ]
             }
    end

    test "leaves out an empty initial text" do
      refute Map.has_key?(rich_text_input(""), :initial_value)
    end
  end
end
