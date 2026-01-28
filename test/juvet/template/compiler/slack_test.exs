defmodule Juvet.Template.Compiler.SlackTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Compiler.Slack

  import Juvet.Test.JsonHelpers, only: [json_equal?: 2]

  describe "compile/1 with basic structure" do
    test "empty AST returns empty blocks" do
      assert json_equal?(Slack.compile([]), %{"blocks" => []})
    end

    test "divider element" do
      ast = [%{platform: :slack, element: :divider, attributes: %{}}]

      assert json_equal?(Slack.compile(ast), %{"blocks" => [%{"type" => "divider"}]})
    end

    test "unknown element raises ArgumentError" do
      ast = [%{platform: :slack, element: :unknown, attributes: %{}}]

      assert_raise ArgumentError, "Unknown Slack element: :unknown", fn ->
        Slack.compile(ast)
      end
    end
  end

  describe "compile/1 with header" do
    test "header with text" do
      ast = [%{platform: :slack, element: :header, attributes: %{text: "Hello"}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Hello"}}
               ]
             })
    end

    test "header with text and emoji" do
      ast = [%{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello", "emoji" => true}
                 }
               ]
             })
    end
  end

  describe "compile/1 with section" do
    test "section with text" do
      ast = [%{platform: :slack, element: :section, attributes: %{text: "Hello *world*"}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "section",
                   "text" => %{"type" => "mrkdwn", "text" => "Hello *world*"}
                 }
               ]
             })
    end

    test "section with text and verbatim" do
      ast = [%{platform: :slack, element: :section, attributes: %{text: "Hello", verbatim: true}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "section",
                   "text" => %{"type" => "mrkdwn", "text" => "Hello", "verbatim" => true}
                 }
               ]
             })
    end

    test "section with image accessory" do
      ast = [
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
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "section",
                   "text" => %{"type" => "mrkdwn", "text" => "Content"},
                   "accessory" => %{
                     "type" => "image",
                     "image_url" => "http://example.com/img.png",
                     "alt_text" => "Alt"
                   }
                 }
               ]
             })
    end

    test "section without accessory still works" do
      ast = [%{platform: :slack, element: :section, attributes: %{text: "No accessory"}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{"type" => "section", "text" => %{"type" => "mrkdwn", "text" => "No accessory"}}
               ]
             })
    end
  end

  describe "compile/1 with image" do
    test "image with url and alt_text" do
      ast = [
        %{
          platform: :slack,
          element: :image,
          attributes: %{url: "http://example.com/img.png", alt_text: "Example"}
        }
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "image",
                   "image_url" => "http://example.com/img.png",
                   "alt_text" => "Example"
                 }
               ]
             })
    end

    test "image with only url" do
      ast = [
        %{platform: :slack, element: :image, attributes: %{url: "http://example.com/img.png"}}
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{"type" => "image", "image_url" => "http://example.com/img.png"}
               ]
             })
    end
  end

  describe "compile/1 with actions" do
    test "actions with single button" do
      ast = [
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

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "actions",
                   "elements" => [
                     %{
                       "type" => "button",
                       "text" => %{"type" => "plain_text", "text" => "Click"},
                       "action_id" => "btn_1"
                     }
                   ]
                 }
               ]
             })
    end

    test "actions with multiple buttons" do
      ast = [
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
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "actions",
                   "elements" => [
                     %{
                       "type" => "button",
                       "text" => %{"type" => "plain_text", "text" => "Button 1"},
                       "action_id" => "btn_1"
                     },
                     %{
                       "type" => "button",
                       "text" => %{"type" => "plain_text", "text" => "Button 2"},
                       "action_id" => "btn_2"
                     }
                   ]
                 }
               ]
             })
    end

    test "actions with no elements returns empty array" do
      ast = [%{platform: :slack, element: :actions, attributes: %{}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [%{"type" => "actions", "elements" => []}]
             })
    end
  end

  describe "compile/1 with context" do
    test "context with text element" do
      ast = [
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
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "context",
                   "elements" => [
                     %{"type" => "mrkdwn", "text" => "Some context"}
                   ]
                 }
               ]
             })
    end

    test "context with image element" do
      ast = [
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
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "context",
                   "elements" => [
                     %{
                       "type" => "image",
                       "image_url" => "http://example.com/icon.png",
                       "alt_text" => "Icon"
                     }
                   ]
                 }
               ]
             })
    end

    test "context with mixed image and text elements" do
      ast = [
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
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "context",
                   "elements" => [
                     %{
                       "type" => "image",
                       "image_url" => "http://example.com/avatar.png",
                       "alt_text" => "Avatar"
                     },
                     %{"type" => "mrkdwn", "text" => "Posted by *John*"}
                   ]
                 }
               ]
             })
    end

    test "context with no elements returns empty array" do
      ast = [%{platform: :slack, element: :context, attributes: %{}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [%{"type" => "context", "elements" => []}]
             })
    end

    test "context with plain_text type" do
      ast = [
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
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "context",
                   "elements" => [
                     %{"type" => "plain_text", "text" => "Plain text"}
                   ]
                 }
               ]
             })
    end
  end

  describe "compile/1 with multiple top-level elements" do
    test "header, divider, and section" do
      ast = [
        %{platform: :slack, element: :header, attributes: %{text: "Welcome"}},
        %{platform: :slack, element: :divider, attributes: %{}},
        %{platform: :slack, element: :section, attributes: %{text: "Content"}}
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Welcome"}},
                 %{"type" => "divider"},
                 %{"type" => "section", "text" => %{"type" => "mrkdwn", "text" => "Content"}}
               ]
             })
    end

    test "multiple sections" do
      ast = [
        %{platform: :slack, element: :section, attributes: %{text: "First"}},
        %{platform: :slack, element: :section, attributes: %{text: "Second"}},
        %{platform: :slack, element: :section, attributes: %{text: "Third"}}
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{"type" => "section", "text" => %{"type" => "mrkdwn", "text" => "First"}},
                 %{"type" => "section", "text" => %{"type" => "mrkdwn", "text" => "Second"}},
                 %{"type" => "section", "text" => %{"type" => "mrkdwn", "text" => "Third"}}
               ]
             })
    end
  end

  describe "compile/1 with interpolation" do
    test "EEx interpolation in header text passes through" do
      ast = [%{platform: :slack, element: :header, attributes: %{text: "Hello <%= name %>"}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello <%= name %>"}
                 }
               ]
             })
    end

    test "EEx interpolation in section text passes through" do
      ast = [%{platform: :slack, element: :section, attributes: %{text: "Welcome <%= user %>!"}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "section",
                   "text" => %{"type" => "mrkdwn", "text" => "Welcome <%= user %>!"}
                 }
               ]
             })
    end

    test "EEx interpolation in button text passes through" do
      ast = [
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
      ]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "actions",
                   "elements" => [
                     %{
                       "type" => "button",
                       "text" => %{"type" => "plain_text", "text" => "<%= action_label %>"},
                       "action_id" => "btn_<%= id %>"
                     }
                   ]
                 }
               ]
             })
    end
  end
end
