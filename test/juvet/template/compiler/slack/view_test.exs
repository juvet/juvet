defmodule Juvet.Template.Compiler.Slack.ViewTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Compiler.Slack

  describe "compile/1 with view" do
    test "view with type and blocks" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal},
          children: %{
            blocks: [
              %{platform: :slack, element: :header, attributes: %{text: "Hello"}},
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               blocks: [
                 %{type: "header", text: %{type: "plain_text", text: "Hello"}},
                 %{type: "divider"}
               ]
             }
    end

    test "view with type, private_metadata, and blocks" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, private_metadata: "some metadata string"},
          children: %{
            blocks: [
              %{platform: :slack, element: :section, attributes: %{text: "Welcome"}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               private_metadata: "some metadata string",
               blocks: [
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Welcome"}
                 }
               ]
             }
    end

    test "view with empty blocks" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal}
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               blocks: []
             }
    end

    test "view without private_metadata omits the field" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :home},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      result = Slack.compile(ast)

      assert result[:type] == "home"
      assert result[:blocks] == [%{type: "divider"}]
      refute Map.has_key?(result, :private_metadata)
    end

    test "view with EEx interpolation in private_metadata passes through" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, private_metadata: "<%= metadata %>"},
          children: %{
            blocks: [
              %{platform: :slack, element: :header, attributes: %{text: "Hello <%= name %>"}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               private_metadata: "<%= metadata %>",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello <%= name %>"}
                 }
               ]
             }
    end

    test "view with multiple block types inside blocks" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal},
          children: %{
            blocks: [
              %{platform: :slack, element: :header, attributes: %{text: "Title"}},
              %{platform: :slack, element: :divider, attributes: %{}},
              %{platform: :slack, element: :section, attributes: %{text: "Content"}},
              %{
                platform: :slack,
                element: :actions,
                attributes: %{},
                children: %{
                  elements: [
                    %{
                      platform: :slack,
                      element: :button,
                      attributes: %{text: "Click", action_id: "btn_1"}
                    }
                  ]
                }
              }
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               blocks: [
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Title"}
                 },
                 %{type: "divider"},
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Content"}
                 },
                 %{
                   type: "actions",
                   elements: [
                     %{
                       type: "button",
                       text: %{type: "plain_text", text: "Click"},
                       action_id: "btn_1"
                     }
                   ]
                 }
               ]
             }
    end
  end
end
