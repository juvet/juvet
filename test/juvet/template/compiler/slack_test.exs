defmodule Juvet.Template.Compiler.SlackTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Compiler.Slack

  defp view_ast(blocks, attrs \\ %{type: :modal}) do
    [
      %{
        platform: :slack,
        element: :view,
        attributes: attrs,
        children: %{blocks: blocks}
      }
    ]
  end

  defp view_expected(blocks, extra \\ %{}) do
    Map.merge(%{type: "modal", blocks: blocks}, extra)
  end

  describe "compile/1 with basic structure" do
    test "divider element" do
      ast = view_ast([%{platform: :slack, element: :divider, attributes: %{}}])

      assert Slack.compile(ast) == view_expected([%{type: "divider"}])
    end

    test "unknown element raises ArgumentError" do
      ast = view_ast([%{platform: :slack, element: :unknown, attributes: %{}}])

      assert_raise ArgumentError, "Unknown Slack element: :unknown", fn ->
        Slack.compile(ast)
      end
    end
  end

  describe "compile/1 with header" do
    test "header with text" do
      ast = view_ast([%{platform: :slack, element: :header, attributes: %{text: "Hello"}}])

      assert Slack.compile(ast) ==
               view_expected([
                 %{type: "header", text: %{type: "plain_text", text: "Hello"}}
               ])
    end

    test "header with text and emoji" do
      ast =
        view_ast([
          %{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello", emoji: true}
                 }
               ])
    end
  end

  describe "compile/1 with section" do
    test "section with text" do
      ast =
        view_ast([%{platform: :slack, element: :section, attributes: %{text: "Hello *world*"}}])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Hello *world*"}
                 }
               ])
    end

    test "section with text and verbatim" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Hello", verbatim: true}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Hello", verbatim: true}
                 }
               ])
    end

    test "section with image accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Content"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :image,
                attributes: %{url: "http://example.com/img.png", alt_text: "Alt"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Content"},
                   accessory: %{
                     type: "image",
                     image_url: "http://example.com/img.png",
                     alt_text: "Alt"
                   }
                 }
               ])
    end

    test "section without accessory still works" do
      ast =
        view_ast([%{platform: :slack, element: :section, attributes: %{text: "No accessory"}}])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "No accessory"}
                 }
               ])
    end
  end

  describe "compile/1 with image" do
    test "image with url and alt_text" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :image,
            attributes: %{url: "http://example.com/img.png", alt_text: "Example"}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "image",
                   image_url: "http://example.com/img.png",
                   alt_text: "Example"
                 }
               ])
    end

    test "image with only url" do
      ast =
        view_ast([
          %{platform: :slack, element: :image, attributes: %{url: "http://example.com/img.png"}}
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{type: "image", image_url: "http://example.com/img.png"}
               ])
    end
  end

  describe "compile/1 with actions" do
    test "actions with single button" do
      ast =
        view_ast([
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
        ])

      assert Slack.compile(ast) ==
               view_expected([
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
               ])
    end

    test "actions with multiple buttons" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :button,
                  attributes: %{text: "Button 1", action_id: "btn_1"}
                },
                %{
                  platform: :slack,
                  element: :button,
                  attributes: %{text: "Button 2", action_id: "btn_2"}
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "actions",
                   elements: [
                     %{
                       type: "button",
                       text: %{type: "plain_text", text: "Button 1"},
                       action_id: "btn_1"
                     },
                     %{
                       type: "button",
                       text: %{type: "plain_text", text: "Button 2"},
                       action_id: "btn_2"
                     }
                   ]
                 }
               ])
    end

    test "actions with no elements returns empty array" do
      ast = view_ast([%{platform: :slack, element: :actions, attributes: %{}}])

      assert Slack.compile(ast) ==
               view_expected([%{type: "actions", elements: []}])
    end
  end

  describe "compile/1 with context" do
    test "context with text element" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :text,
                  attributes: %{text: "Some context"}
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "context",
                   elements: [
                     %{type: "mrkdwn", text: "Some context"}
                   ]
                 }
               ])
    end

    test "context with image element" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :image,
                  attributes: %{url: "http://example.com/icon.png", alt_text: "Icon"}
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "context",
                   elements: [
                     %{
                       type: "image",
                       image_url: "http://example.com/icon.png",
                       alt_text: "Icon"
                     }
                   ]
                 }
               ])
    end

    test "context with mixed image and text elements" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :image,
                  attributes: %{url: "http://example.com/avatar.png", alt_text: "Avatar"}
                },
                %{
                  platform: :slack,
                  element: :text,
                  attributes: %{text: "Posted by *John*"}
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "context",
                   elements: [
                     %{
                       type: "image",
                       image_url: "http://example.com/avatar.png",
                       alt_text: "Avatar"
                     },
                     %{type: "mrkdwn", text: "Posted by *John*"}
                   ]
                 }
               ])
    end

    test "context with no elements returns empty array" do
      ast = view_ast([%{platform: :slack, element: :context, attributes: %{}}])

      assert Slack.compile(ast) ==
               view_expected([%{type: "context", elements: []}])
    end

    test "context with plain_text type" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :text,
                  attributes: %{text: "Plain text", type: :plain_text}
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "context",
                   elements: [
                     %{type: "plain_text", text: "Plain text"}
                   ]
                 }
               ])
    end
  end

  describe "compile/1 with multiple top-level elements" do
    test "header, divider, and section" do
      ast =
        view_ast([
          %{platform: :slack, element: :header, attributes: %{text: "Welcome"}},
          %{platform: :slack, element: :divider, attributes: %{}},
          %{platform: :slack, element: :section, attributes: %{text: "Content"}}
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Welcome"}
                 },
                 %{type: "divider"},
                 %{type: "section", text: %{type: "mrkdwn", text: "Content"}}
               ])
    end

    test "multiple sections" do
      ast =
        view_ast([
          %{platform: :slack, element: :section, attributes: %{text: "First"}},
          %{platform: :slack, element: :section, attributes: %{text: "Second"}},
          %{platform: :slack, element: :section, attributes: %{text: "Third"}}
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{type: "section", text: %{type: "mrkdwn", text: "First"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "Second"}},
                 %{type: "section", text: %{type: "mrkdwn", text: "Third"}}
               ])
    end
  end

  describe "compile/1 with interpolation" do
    test "EEx interpolation in header text passes through" do
      ast =
        view_ast([
          %{platform: :slack, element: :header, attributes: %{text: "Hello <%= name %>"}}
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello <%= name %>"}
                 }
               ])
    end

    test "EEx interpolation in section text passes through" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Welcome <%= user %>!"}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Welcome <%= user %>!"}
                 }
               ])
    end

    test "EEx interpolation in button text passes through" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :button,
                  attributes: %{text: "<%= action_label %>", action_id: "btn_<%= id %>"}
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "actions",
                   elements: [
                     %{
                       type: "button",
                       text: %{type: "plain_text", text: "<%= action_label %>"},
                       action_id: "btn_<%= id %>"
                     }
                   ]
                 }
               ])
    end
  end
end
