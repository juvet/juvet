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

    test "view with callback_id includes the callback_id field" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, callback_id: "submit_decision_modal"},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               callback_id: "submit_decision_modal",
               blocks: [%{type: "divider"}]
             }
    end

    test "view with title as a plain string wraps it in a plain_text object" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, title: "New Decision"},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               title: %{type: "plain_text", text: "New Decision"},
               blocks: [%{type: "divider"}]
             }
    end

    test "view with clear_on_close boolean includes the field" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, clear_on_close: true},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               clear_on_close: true,
               blocks: [%{type: "divider"}]
             }
    end

    test "view with title as a nested map honors text and emoji" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, title: %{text: "New Decision", emoji: true}},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               title: %{type: "plain_text", text: "New Decision", emoji: true},
               blocks: [%{type: "divider"}]
             }
    end

    test "view with submit as a string wraps it in a plain_text object" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, submit: "Save"},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               submit: %{type: "plain_text", text: "Save"},
               blocks: [%{type: "divider"}]
             }
    end

    test "view with close as a string wraps it in a plain_text object" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, close: "Cancel"},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               close: %{type: "plain_text", text: "Cancel"},
               blocks: [%{type: "divider"}]
             }
    end

    test "view with notify_on_close boolean includes the field" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, notify_on_close: true},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               notify_on_close: true,
               blocks: [%{type: "divider"}]
             }
    end

    test "view with external_id includes the field" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, external_id: "modal-42"},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               external_id: "modal-42",
               blocks: [%{type: "divider"}]
             }
    end

    test "view with submit_disabled boolean includes the field" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, submit_disabled: true},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               submit_disabled: true,
               blocks: [%{type: "divider"}]
             }
    end

    test "view without modal envelope fields omits all of them" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      result = Slack.compile(ast)

      refute Map.has_key?(result, :callback_id)
      refute Map.has_key?(result, :title)
      refute Map.has_key?(result, :submit)
      refute Map.has_key?(result, :close)
      refute Map.has_key?(result, :clear_on_close)
      refute Map.has_key?(result, :notify_on_close)
      refute Map.has_key?(result, :external_id)
      refute Map.has_key?(result, :submit_disabled)
    end

    test "view with all modal envelope fields together" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{
            type: :modal,
            callback_id: "submit_decision_modal",
            title: %{text: "New Decision", emoji: true},
            submit: "Save",
            close: "Cancel",
            private_metadata: "decision-42",
            clear_on_close: true,
            notify_on_close: true,
            external_id: "modal-42",
            submit_disabled: false
          },
          children: %{
            blocks: [
              %{platform: :slack, element: :section, attributes: %{text: "Are you sure?"}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               callback_id: "submit_decision_modal",
               title: %{type: "plain_text", text: "New Decision", emoji: true},
               submit: %{type: "plain_text", text: "Save"},
               close: %{type: "plain_text", text: "Cancel"},
               private_metadata: "decision-42",
               clear_on_close: true,
               notify_on_close: true,
               external_id: "modal-42",
               submit_disabled: false,
               blocks: [
                 %{type: "section", text: %{type: "mrkdwn", text: "Are you sure?"}}
               ]
             }
    end

    test "view with EEx interpolation in title text passes through at compile time" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal, title: %{text: "<%= @subject %>", emoji: true}},
          children: %{
            blocks: [
              %{platform: :slack, element: :divider, attributes: %{}}
            ]
          }
        }
      ]

      assert Slack.compile(ast) == %{
               type: "modal",
               title: %{type: "plain_text", text: "<%= @subject %>", emoji: true},
               blocks: [%{type: "divider"}]
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
