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

  describe "compile/1 with option" do
    test "option with text and value" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :static, action_id: "sel_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Option 1", value: "opt_1"}
                    }
                  ]
                }
              }
            }
          }
        ])

      result = Slack.compile(ast)
      [section] = result.blocks
      [option] = section.accessory.options

      assert option == %{
               text: %{type: "plain_text", text: "Option 1"},
               value: "opt_1"
             }
    end

    test "option with description" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :static, action_id: "sel_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{
                        text: "Option 1",
                        value: "opt_1",
                        description: "First option"
                      }
                    }
                  ]
                }
              }
            }
          }
        ])

      result = Slack.compile(ast)
      [section] = result.blocks
      [option] = section.accessory.options

      assert option == %{
               text: %{type: "plain_text", text: "Option 1"},
               value: "opt_1",
               description: %{type: "plain_text", text: "First option"}
             }
    end
  end

  describe "compile/1 with option missing required attributes" do
    test "option missing value raises ArgumentError" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :static, action_id: "sel_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Option 1"}
                    }
                  ]
                }
              }
            }
          }
        ])

      assert_raise ArgumentError,
                   "option element is missing required attribute(s): value",
                   fn -> Slack.compile(ast) end
    end

    test "option missing text raises ArgumentError" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :static, action_id: "sel_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{value: "opt_1"}
                    }
                  ]
                }
              }
            }
          }
        ])

      assert_raise ArgumentError,
                   "option element is missing required attribute(s): text",
                   fn -> Slack.compile(ast) end
    end

    test "option missing both text and value raises ArgumentError" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :static, action_id: "sel_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{}
                    }
                  ]
                }
              }
            }
          }
        ])

      assert_raise ArgumentError,
                   "option element is missing required attribute(s): text, value",
                   fn -> Slack.compile(ast) end
    end

    test "option missing value includes location when available" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :static, action_id: "sel_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Option 1"},
                      line: 5,
                      column: 7
                    }
                  ]
                }
              }
            }
          }
        ])

      assert_raise ArgumentError,
                   "option element is missing required attribute(s): value (line 5, column 7)",
                   fn -> Slack.compile(ast) end
    end
  end

  describe "compile/1 with option_group" do
    test "option group with label and options" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :static, action_id: "sel_1"},
                children: %{
                  option_groups: [
                    %{
                      platform: :slack,
                      element: :option_group,
                      attributes: %{label: "Group 1"},
                      children: %{
                        options: [
                          %{
                            platform: :slack,
                            element: :option,
                            attributes: %{text: "Option A", value: "a"}
                          },
                          %{
                            platform: :slack,
                            element: :option,
                            attributes: %{text: "Option B", value: "b"}
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            }
          }
        ])

      result = Slack.compile(ast)
      [section] = result.blocks
      [group] = section.accessory.option_groups

      assert group == %{
               label: %{type: "plain_text", text: "Group 1"},
               options: [
                 %{text: %{type: "plain_text", text: "Option A"}, value: "a"},
                 %{text: %{type: "plain_text", text: "Option B"}, value: "b"}
               ]
             }
    end
  end

  describe "compile/1 with select source: :static" do
    test "compiles to static_select type" do
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
                  element: :select,
                  attributes: %{source: :static, action_id: "sel_1"},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Option 1", value: "opt_1"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "static_select"
      assert select.action_id == "sel_1"
      assert length(select.options) == 1
    end

    test "multi-select compiles to multi_static_select" do
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
                  element: :select,
                  attributes: %{
                    source: :static,
                    multiple: true,
                    action_id: "sel_1",
                    max_selected_items: 3
                  },
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Option 1", value: "opt_1"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Option 2", value: "opt_2"}
                      }
                    ],
                    initial_options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Option 1", value: "opt_1"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "multi_static_select"
      assert select.max_selected_items == 3

      assert select.initial_options == [
               %{text: %{type: "plain_text", text: "Option 1"}, value: "opt_1"}
             ]
    end
  end

  describe "compile/1 with select source: :external" do
    test "compiles to external_select type" do
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
                  element: :select,
                  attributes: %{source: :external, action_id: "sel_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select == %{type: "external_select", action_id: "sel_1"}
    end

    test "with min_query_length" do
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
                  element: :select,
                  attributes: %{
                    source: :external,
                    action_id: "sel_1",
                    min_query_length: 3
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "external_select"
      assert select.min_query_length == 3
    end

    test "with initial_option" do
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
                  element: :select,
                  attributes: %{source: :external, action_id: "sel_1"},
                  children: %{
                    initial_option: %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Preloaded", value: "pre"}
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.initial_option == %{
               text: %{type: "plain_text", text: "Preloaded"},
               value: "pre"
             }
    end

    test "multi-select with initial_options" do
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
                  element: :select,
                  attributes: %{source: :external, multiple: true, action_id: "sel_1"},
                  children: %{
                    initial_options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "A", value: "a"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "B", value: "b"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "multi_external_select"

      assert select.initial_options == [
               %{text: %{type: "plain_text", text: "A"}, value: "a"},
               %{text: %{type: "plain_text", text: "B"}, value: "b"}
             ]
    end
  end

  describe "compile/1 with select source: :users" do
    test "compiles to users_select type" do
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
                  element: :select,
                  attributes: %{source: :users, action_id: "sel_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select == %{type: "users_select", action_id: "sel_1"}
    end

    test "with initial_user" do
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
                  element: :select,
                  attributes: %{source: :users, action_id: "sel_1", initial_user: "U12345"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "users_select"
      assert select.initial_user == "U12345"
    end

    test "multi-select with initial_users and max_selected_items" do
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
                  element: :select,
                  attributes: %{
                    source: :users,
                    multiple: true,
                    action_id: "sel_1",
                    initial_users: ["U111", "U222"],
                    max_selected_items: 5
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "multi_users_select"
      assert select.initial_users == ["U111", "U222"]
      assert select.max_selected_items == 5
    end
  end

  describe "compile/1 with select source: :conversations" do
    test "compiles to conversations_select type" do
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
                  element: :select,
                  attributes: %{source: :conversations, action_id: "sel_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select == %{type: "conversations_select", action_id: "sel_1"}
    end

    test "with initial_conversation" do
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
                  element: :select,
                  attributes: %{
                    source: :conversations,
                    action_id: "sel_1",
                    initial_conversation: "C12345"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "conversations_select"
      assert select.initial_conversation == "C12345"
    end

    test "with default_to_current_conversation" do
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
                  element: :select,
                  attributes: %{
                    source: :conversations,
                    action_id: "sel_1",
                    default_to_current_conversation: true
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "conversations_select"
      assert select.default_to_current_conversation == true
    end

    test "with filter" do
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
                  element: :select,
                  attributes: %{source: :conversations, action_id: "sel_1"},
                  children: %{
                    filter: %{
                      platform: :slack,
                      element: :filter,
                      attributes: %{
                        include: ["im", "public"],
                        exclude_external_shared_channels: true,
                        exclude_bot_users: true
                      }
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "conversations_select"

      assert select.filter == %{
               include: ["im", "public"],
               exclude_external_shared_channels: true,
               exclude_bot_users: true
             }
    end

    test "multi-select with initial_conversations" do
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
                  element: :select,
                  attributes: %{
                    source: :conversations,
                    multiple: true,
                    action_id: "sel_1",
                    initial_conversations: ["C111", "C222"]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "multi_conversations_select"
      assert select.initial_conversations == ["C111", "C222"]
    end
  end

  describe "compile/1 with select source: :channels" do
    test "compiles to channels_select type" do
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
                  element: :select,
                  attributes: %{source: :channels, action_id: "sel_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select == %{type: "channels_select", action_id: "sel_1"}
    end

    test "with initial_channel" do
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
                  element: :select,
                  attributes: %{
                    source: :channels,
                    action_id: "sel_1",
                    initial_channel: "C12345"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "channels_select"
      assert select.initial_channel == "C12345"
    end

    test "multi-select with initial_channels" do
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
                  element: :select,
                  attributes: %{
                    source: :channels,
                    multiple: true,
                    action_id: "sel_1",
                    initial_channels: ["C111", "C222"]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.type == "multi_channels_select"
      assert select.initial_channels == ["C111", "C222"]
    end
  end

  describe "compile/1 with select in different contexts" do
    test "select as actions element" do
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
                  element: :select,
                  attributes: %{source: :users, action_id: "user_sel"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select == %{type: "users_select", action_id: "user_sel"}
    end

    test "select as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick a user"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :users, action_id: "user_sel"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Pick a user"},
                   accessory: %{
                     type: "users_select",
                     action_id: "user_sel"
                   }
                 }
               ])
    end
  end

  describe "compile/1 with overflow" do
    test "overflow with single option" do
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
                  element: :overflow,
                  attributes: %{action_id: "overflow_1"},
                  children: %{
                    options: %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Edit", value: "edit"}
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [overflow] = actions.elements

      assert overflow == %{
               type: "overflow",
               action_id: "overflow_1",
               options: [
                 %{text: %{type: "plain_text", text: "Edit"}, value: "edit"}
               ]
             }
    end

    test "overflow with options in actions block" do
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
                  element: :overflow,
                  attributes: %{},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Edit", value: "edit"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Delete", value: "delete"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [overflow] = actions.elements

      assert overflow == %{
               type: "overflow",
               options: [
                 %{text: %{type: "plain_text", text: "Edit"}, value: "edit"},
                 %{text: %{type: "plain_text", text: "Delete"}, value: "delete"}
               ]
             }
    end

    test "overflow as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Settings"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :overflow,
                attributes: %{action_id: "overflow_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Edit", value: "edit"}
                    },
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Archive", value: "archive"}
                    }
                  ]
                }
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Settings"},
                   accessory: %{
                     type: "overflow",
                     action_id: "overflow_1",
                     options: [
                       %{text: %{type: "plain_text", text: "Edit"}, value: "edit"},
                       %{text: %{type: "plain_text", text: "Archive"}, value: "archive"}
                     ]
                   }
                 }
               ])
    end

    test "overflow with action_id" do
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
                  element: :overflow,
                  attributes: %{action_id: "more_options"},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Option 1", value: "opt_1"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Option 2", value: "opt_2"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [overflow] = actions.elements

      assert overflow.type == "overflow"
      assert overflow.action_id == "more_options"
      assert length(overflow.options) == 2
    end
  end

  describe "compile/1 with datetimepicker" do
    test "datetimepicker with action_id and initial_date_time in actions block" do
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
                  element: :datetimepicker,
                  attributes: %{action_id: "datetime_1", initial_date_time: 1_628_633_820}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datetimepicker] = actions.elements

      assert datetimepicker == %{
               type: "datetimepicker",
               action_id: "datetime_1",
               initial_date_time: 1_628_633_820
             }
    end

    test "datetimepicker as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick a date and time"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :datetimepicker,
                attributes: %{action_id: "datetime_1"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Pick a date and time"},
                   accessory: %{
                     type: "datetimepicker",
                     action_id: "datetime_1"
                   }
                 }
               ])
    end

    test "datetimepicker with focus_on_load" do
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
                  element: :datetimepicker,
                  attributes: %{action_id: "datetime_1", focus_on_load: true}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datetimepicker] = actions.elements

      assert datetimepicker == %{
               type: "datetimepicker",
               action_id: "datetime_1",
               focus_on_load: true
             }
    end

    test "datetimepicker with only action_id" do
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
                  element: :datetimepicker,
                  attributes: %{action_id: "datetime_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datetimepicker] = actions.elements

      assert datetimepicker == %{type: "datetimepicker", action_id: "datetime_1"}
    end
  end

  describe "compile/1 with image element" do
    test "image element with slack_file as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Profile photo"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :image,
                attributes: %{slack_file: %{id: "F0123456"}, alt_text: "Avatar"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Profile photo"},
                   accessory: %{
                     type: "image",
                     slack_file: %{id: "F0123456"},
                     alt_text: "Avatar"
                   }
                 }
               ])
    end

    test "image element with slack_file in context" do
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
                  attributes: %{slack_file: %{id: "F0123456"}, alt_text: "Icon"}
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
                       slack_file: %{id: "F0123456"},
                       alt_text: "Icon"
                     }
                   ]
                 }
               ])
    end

    test "image element with url and alt_text in context" do
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
  end

  describe "compile/1 with timepicker" do
    test "timepicker with action_id and initial_time in actions block" do
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
                  element: :timepicker,
                  attributes: %{action_id: "time_1", initial_time: "09:30"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [timepicker] = actions.elements

      assert timepicker == %{
               type: "timepicker",
               action_id: "time_1",
               initial_time: "09:30"
             }
    end

    test "timepicker as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick a time"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :timepicker,
                attributes: %{action_id: "time_1"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Pick a time"},
                   accessory: %{
                     type: "timepicker",
                     action_id: "time_1"
                   }
                 }
               ])
    end

    test "timepicker with scalar placeholder" do
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
                  element: :timepicker,
                  attributes: %{action_id: "time_1", placeholder: "Select a time"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [timepicker] = actions.elements

      assert timepicker == %{
               type: "timepicker",
               action_id: "time_1",
               placeholder: %{type: "plain_text", text: "Select a time"}
             }
    end

    test "timepicker with timezone" do
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
                  element: :timepicker,
                  attributes: %{action_id: "time_1", timezone: "America/Chicago"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [timepicker] = actions.elements

      assert timepicker == %{
               type: "timepicker",
               action_id: "time_1",
               timezone: "America/Chicago"
             }
    end

    test "timepicker with focus_on_load" do
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
                  element: :timepicker,
                  attributes: %{action_id: "time_1", focus_on_load: true}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [timepicker] = actions.elements

      assert timepicker == %{
               type: "timepicker",
               action_id: "time_1",
               focus_on_load: true
             }
    end
  end

  describe "compile/1 with checkboxes" do
    test "checkboxes with options in actions block" do
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
                  element: :checkboxes,
                  attributes: %{action_id: "chk_1"},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Email", value: "email"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "SMS", value: "sms"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [checkboxes] = actions.elements

      assert checkboxes == %{
               type: "checkboxes",
               action_id: "chk_1",
               options: [
                 %{text: %{type: "plain_text", text: "Email"}, value: "email"},
                 %{text: %{type: "plain_text", text: "SMS"}, value: "sms"}
               ]
             }
    end

    test "checkboxes with initial_options" do
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
                  element: :checkboxes,
                  attributes: %{action_id: "chk_1"},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Email", value: "email"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "SMS", value: "sms"}
                      }
                    ],
                    initial_options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Email", value: "email"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [checkboxes] = actions.elements

      assert checkboxes.initial_options == [
               %{text: %{type: "plain_text", text: "Email"}, value: "email"}
             ]
    end

    test "checkboxes as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Notifications"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :checkboxes,
                attributes: %{action_id: "chk_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Email", value: "email"}
                    }
                  ]
                }
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Notifications"},
                   accessory: %{
                     type: "checkboxes",
                     action_id: "chk_1",
                     options: [
                       %{text: %{type: "plain_text", text: "Email"}, value: "email"}
                     ]
                   }
                 }
               ])
    end

    test "checkboxes with focus_on_load" do
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
                  element: :checkboxes,
                  attributes: %{action_id: "chk_1", focus_on_load: true},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Option", value: "opt"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [checkboxes] = actions.elements

      assert checkboxes.focus_on_load == true
    end
  end

  describe "compile/1 with radio_buttons" do
    test "radio_buttons with options in actions block" do
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
                  element: :radio_buttons,
                  attributes: %{action_id: "radio_1"},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Small", value: "sm"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Medium", value: "md"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Large", value: "lg"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [radio] = actions.elements

      assert radio == %{
               type: "radio_buttons",
               action_id: "radio_1",
               options: [
                 %{text: %{type: "plain_text", text: "Small"}, value: "sm"},
                 %{text: %{type: "plain_text", text: "Medium"}, value: "md"},
                 %{text: %{type: "plain_text", text: "Large"}, value: "lg"}
               ]
             }
    end

    test "radio_buttons with initial_option" do
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
                  element: :radio_buttons,
                  attributes: %{action_id: "radio_1"},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Small", value: "sm"}
                      },
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Large", value: "lg"}
                      }
                    ],
                    initial_option: %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Small", value: "sm"}
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [radio] = actions.elements

      assert radio.initial_option == %{
               text: %{type: "plain_text", text: "Small"},
               value: "sm"
             }
    end

    test "radio_buttons as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick a size"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :radio_buttons,
                attributes: %{action_id: "radio_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Small", value: "sm"}
                    },
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Large", value: "lg"}
                    }
                  ]
                }
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Pick a size"},
                   accessory: %{
                     type: "radio_buttons",
                     action_id: "radio_1",
                     options: [
                       %{text: %{type: "plain_text", text: "Small"}, value: "sm"},
                       %{text: %{type: "plain_text", text: "Large"}, value: "lg"}
                     ]
                   }
                 }
               ])
    end
  end

  describe "compile/1 with plain_text_input" do
    test "plain_text_input with action_id" do
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
                  element: :plain_text_input,
                  attributes: %{action_id: "input_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{type: "plain_text_input", action_id: "input_1"}
    end

    test "plain_text_input with all optional fields" do
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
                  element: :plain_text_input,
                  attributes: %{
                    action_id: "input_1",
                    initial_value: "Hello",
                    multiline: true,
                    min_length: 5,
                    max_length: 100,
                    placeholder: "Enter text",
                    focus_on_load: true
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "plain_text_input",
               action_id: "input_1",
               initial_value: "Hello",
               multiline: true,
               min_length: 5,
               max_length: 100,
               placeholder: %{type: "plain_text", text: "Enter text"},
               focus_on_load: true
             }
    end

    test "plain_text_input with deep placeholder" do
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
                  element: :plain_text_input,
                  attributes: %{
                    action_id: "input_1",
                    placeholder: %{text: "Type here", emoji: true}
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input.placeholder == %{
               type: "plain_text",
               text: "Type here",
               emoji: true
             }
    end
  end

  describe "compile/1 with email_input" do
    test "email_input with action_id" do
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
                  element: :email_input,
                  attributes: %{action_id: "email_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{type: "email_text_input", action_id: "email_1"}
    end

    test "email_input with initial_value and placeholder" do
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
                  element: :email_input,
                  attributes: %{
                    action_id: "email_1",
                    initial_value: "user@example.com",
                    placeholder: "Enter email"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "email_text_input",
               action_id: "email_1",
               initial_value: "user@example.com",
               placeholder: %{type: "plain_text", text: "Enter email"}
             }
    end

    test "email_input with focus_on_load" do
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
                  element: :email_input,
                  attributes: %{action_id: "email_1", focus_on_load: true}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "email_text_input",
               action_id: "email_1",
               focus_on_load: true
             }
    end
  end

  describe "compile/1 with url_input" do
    test "url_input with action_id" do
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
                  element: :url_input,
                  attributes: %{action_id: "url_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{type: "url_text_input", action_id: "url_1"}
    end

    test "url_input with initial_value and placeholder" do
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
                  element: :url_input,
                  attributes: %{
                    action_id: "url_1",
                    initial_value: "https://example.com",
                    placeholder: "Enter URL"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "url_text_input",
               action_id: "url_1",
               initial_value: "https://example.com",
               placeholder: %{type: "plain_text", text: "Enter URL"}
             }
    end

    test "url_input with focus_on_load" do
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
                  element: :url_input,
                  attributes: %{action_id: "url_1", focus_on_load: true}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "url_text_input",
               action_id: "url_1",
               focus_on_load: true
             }
    end
  end

  describe "compile/1 with number_input" do
    test "number_input with is_decimal_allowed" do
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
                  element: :number_input,
                  attributes: %{action_id: "num_1", is_decimal_allowed: true}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "number_input",
               action_id: "num_1",
               is_decimal_allowed: true
             }
    end

    test "number_input with min_value and max_value" do
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
                  element: :number_input,
                  attributes: %{
                    action_id: "num_1",
                    is_decimal_allowed: false,
                    min_value: "0",
                    max_value: "100"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "number_input",
               action_id: "num_1",
               is_decimal_allowed: false,
               min_value: "0",
               max_value: "100"
             }
    end

    test "number_input with initial_value and placeholder" do
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
                  element: :number_input,
                  attributes: %{
                    action_id: "num_1",
                    is_decimal_allowed: true,
                    initial_value: "42",
                    placeholder: "Enter a number"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "number_input",
               action_id: "num_1",
               is_decimal_allowed: true,
               initial_value: "42",
               placeholder: %{type: "plain_text", text: "Enter a number"}
             }
    end
  end

  describe "compile/1 with file_input" do
    test "file_input with action_id" do
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
                  element: :file_input,
                  attributes: %{action_id: "file_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{type: "file_input", action_id: "file_1"}
    end

    test "file_input with filetypes and max_files" do
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
                  element: :file_input,
                  attributes: %{
                    action_id: "file_1",
                    filetypes: ["pdf", "jpg", "png"],
                    max_files: 3
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "file_input",
               action_id: "file_1",
               filetypes: ["pdf", "jpg", "png"],
               max_files: 3
             }
    end
  end

  describe "compile/1 with rich_text_input" do
    test "rich_text_input with action_id" do
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
                  element: :rich_text_input,
                  attributes: %{action_id: "rich_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{type: "rich_text_input", action_id: "rich_1"}
    end

    test "rich_text_input with placeholder and focus_on_load" do
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
                  element: :rich_text_input,
                  attributes: %{
                    action_id: "rich_1",
                    placeholder: "Write something",
                    focus_on_load: true
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [input] = actions.elements

      assert input == %{
               type: "rich_text_input",
               action_id: "rich_1",
               placeholder: %{type: "plain_text", text: "Write something"},
               focus_on_load: true
             }
    end
  end

  describe "compile/1 with datepicker" do
    test "datepicker with action_id and initial_date in actions block" do
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
                  element: :datepicker,
                  attributes: %{action_id: "date_1", initial_date: "2024-01-15"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datepicker] = actions.elements

      assert datepicker == %{
               type: "datepicker",
               action_id: "date_1",
               initial_date: "2024-01-15"
             }
    end

    test "datepicker as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick a date"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :datepicker,
                attributes: %{action_id: "date_1", initial_date: "2024-06-01"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Pick a date"},
                   accessory: %{
                     type: "datepicker",
                     action_id: "date_1",
                     initial_date: "2024-06-01"
                   }
                 }
               ])
    end

    test "datepicker with scalar placeholder" do
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
                  element: :datepicker,
                  attributes: %{action_id: "date_1", placeholder: "Select a date"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datepicker] = actions.elements

      assert datepicker == %{
               type: "datepicker",
               action_id: "date_1",
               placeholder: %{type: "plain_text", text: "Select a date"}
             }
    end

    test "datepicker with deep placeholder" do
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
                  element: :datepicker,
                  attributes: %{
                    action_id: "date_1",
                    placeholder: %{text: "Choose a date", emoji: true}
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datepicker] = actions.elements

      assert datepicker == %{
               type: "datepicker",
               action_id: "date_1",
               placeholder: %{type: "plain_text", text: "Choose a date", emoji: true}
             }
    end

    test "datepicker with focus_on_load" do
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
                  element: :datepicker,
                  attributes: %{action_id: "date_1", focus_on_load: true}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datepicker] = actions.elements

      assert datepicker == %{
               type: "datepicker",
               action_id: "date_1",
               focus_on_load: true
             }
    end

    test "datepicker with only action_id" do
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
                  element: :datepicker,
                  attributes: %{action_id: "date_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datepicker] = actions.elements

      assert datepicker == %{type: "datepicker", action_id: "date_1"}
    end
  end

  describe "compile/1 with feedback_buttons" do
    test "feedback_buttons with positive and negative buttons in context_actions block" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :feedback_buttons,
                  attributes: %{
                    positive_button: %{text: "Helpful", value: "yes"},
                    negative_button: %{text: "Not Helpful", value: "no"}
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [context_actions] = result.blocks
      [fb] = context_actions.elements

      assert fb == %{
               type: "feedback_buttons",
               positive_button: %{
                 text: %{type: "plain_text", text: "Helpful"},
                 value: "yes"
               },
               negative_button: %{
                 text: %{type: "plain_text", text: "Not Helpful"},
                 value: "no"
               }
             }
    end

    test "feedback_buttons with accessibility_labels on sub-buttons" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :feedback_buttons,
                  attributes: %{
                    positive_button: %{
                      text: "Good",
                      value: "good",
                      accessibility_label: "Mark as good"
                    },
                    negative_button: %{
                      text: "Bad",
                      value: "bad",
                      accessibility_label: "Mark as bad"
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [context_actions] = result.blocks
      [fb] = context_actions.elements

      assert fb.positive_button.accessibility_label == "Mark as good"
      assert fb.negative_button.accessibility_label == "Mark as bad"
    end

    test "feedback_buttons with action_id" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :feedback_buttons,
                  attributes: %{
                    action_id: "fb_1",
                    positive_button: %{text: "Yes", value: "yes"},
                    negative_button: %{text: "No", value: "no"}
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [context_actions] = result.blocks
      [fb] = context_actions.elements

      assert fb.action_id == "fb_1"
    end
  end

  describe "compile/1 with icon_button" do
    test "icon_button with icon, text, action_id in context_actions block" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :icon_button,
                  attributes: %{
                    icon: "trash",
                    text: "Delete",
                    action_id: "delete_btn"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [context_actions] = result.blocks
      [icon_btn] = context_actions.elements

      assert icon_btn == %{
               type: "icon_button",
               icon: "trash",
               text: %{type: "plain_text", text: "Delete"},
               action_id: "delete_btn"
             }
    end

    test "icon_button with value and accessibility_label" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :icon_button,
                  attributes: %{
                    icon: "edit",
                    text: "Edit",
                    action_id: "edit_btn",
                    value: "item_123",
                    accessibility_label: "Edit this item"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [context_actions] = result.blocks
      [icon_btn] = context_actions.elements

      assert icon_btn.value == "item_123"
      assert icon_btn.accessibility_label == "Edit this item"
    end

    test "icon_button with visible_to_user_ids" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :icon_button,
                  attributes: %{
                    icon: "trash",
                    text: "Delete",
                    action_id: "delete_btn",
                    visible_to_user_ids: ["U111", "U222"]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [context_actions] = result.blocks
      [icon_btn] = context_actions.elements

      assert icon_btn.visible_to_user_ids == ["U111", "U222"]
    end

    test "icon_button with deep text" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :icon_button,
                  attributes: %{
                    icon: "star",
                    text: %{text: "Favorite", emoji: true},
                    action_id: "fav_btn"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [context_actions] = result.blocks
      [icon_btn] = context_actions.elements

      assert icon_btn.text == %{type: "plain_text", text: "Favorite", emoji: true}
    end
  end

  describe "compile/1 with workflow_button" do
    test "workflow_button with text and workflow trigger in actions block" do
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
                  element: :workflow_button,
                  attributes: %{
                    text: "Run Workflow",
                    action_id: "wf_btn_1",
                    workflow: %{
                      trigger: %{
                        url: "https://slack.com/shortcuts/Ft123/xyz"
                      }
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [wf_button] = actions.elements

      assert wf_button == %{
               type: "workflow_button",
               text: %{type: "plain_text", text: "Run Workflow"},
               action_id: "wf_btn_1",
               workflow: %{
                 trigger: %{
                   url: "https://slack.com/shortcuts/Ft123/xyz"
                 }
               }
             }
    end

    test "workflow_button with customizable_input_parameters" do
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
                  element: :workflow_button,
                  attributes: %{
                    text: "Start",
                    action_id: "wf_btn_2",
                    workflow: %{
                      trigger: %{
                        url: "https://slack.com/shortcuts/Ft123/xyz",
                        customizable_input_parameters: [
                          %{name: "greeting", value: "Hello"}
                        ]
                      }
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [wf_button] = actions.elements

      assert wf_button.workflow.trigger.customizable_input_parameters == [
               %{name: "greeting", value: "Hello"}
             ]
    end

    test "workflow_button with style and accessibility_label" do
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
                  element: :workflow_button,
                  attributes: %{
                    text: "Deploy",
                    action_id: "wf_btn_3",
                    style: "primary",
                    accessibility_label: "Deploy to production"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [wf_button] = actions.elements

      assert wf_button.type == "workflow_button"
      assert wf_button.style == "primary"
      assert wf_button.accessibility_label == "Deploy to production"
    end

    test "workflow_button with deep text" do
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
                  element: :workflow_button,
                  attributes: %{
                    text: %{text: "Run It", emoji: true},
                    action_id: "wf_btn_4"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [wf_button] = actions.elements

      assert wf_button.text == %{type: "plain_text", text: "Run It", emoji: true}
    end
  end

  describe "compile/1 with context_actions" do
    test "context_actions block with elements" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
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

      result = Slack.compile(ast)
      [context_actions] = result.blocks

      assert context_actions == %{
               type: "context_actions",
               elements: [
                 %{
                   type: "button",
                   text: %{type: "plain_text", text: "Click"},
                   action_id: "btn_1"
                 }
               ]
             }
    end

    test "context_actions block with no elements" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :context_actions,
            attributes: %{}
          }
        ])

      result = Slack.compile(ast)
      [context_actions] = result.blocks

      assert context_actions == %{type: "context_actions", elements: []}
    end
  end

  describe "compile/1 with deep attributes" do
    test "select with placeholder as deep attribute" do
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
                  element: :select,
                  attributes: %{
                    source: :static,
                    action_id: "sel_1",
                    placeholder: %{text: "Choose a color", emoji: true}
                  },
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Red", value: "red"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.placeholder == %{
               type: "plain_text",
               text: "Choose a color",
               emoji: true
             }
    end

    test "button with text as deep attribute" do
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
                  attributes: %{
                    text: %{text: "Click me", emoji: true},
                    action_id: "btn_1"
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [button] = actions.elements

      assert button.text == %{type: "plain_text", text: "Click me", emoji: true}
      assert button.action_id == "btn_1"
    end

    test "header with text as deep attribute" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :header,
            attributes: %{text: %{text: "Hello", emoji: true}}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "header",
                   text: %{type: "plain_text", text: "Hello", emoji: true}
                 }
               ])
    end

    test "section with text as deep attribute" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: %{text: "Hello", verbatim: true}}
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

  describe "compile/1 with table" do
    test "table block with rows of raw_text cells" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :table,
            attributes: %{},
            children: %{
              rows: [
                [
                  %{platform: :slack, element: :raw_text, attributes: %{text: "Name"}},
                  %{platform: :slack, element: :raw_text, attributes: %{text: "Role"}}
                ],
                [
                  %{platform: :slack, element: :raw_text, attributes: %{text: "Alice"}},
                  %{platform: :slack, element: :raw_text, attributes: %{text: "Engineer"}}
                ]
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "table",
                   rows: [
                     %{
                       cells: [
                         %{type: "raw_text", text: "Name"},
                         %{type: "raw_text", text: "Role"}
                       ]
                     },
                     %{
                       cells: [
                         %{type: "raw_text", text: "Alice"},
                         %{type: "raw_text", text: "Engineer"}
                       ]
                     }
                   ]
                 }
               ])
    end

    test "table block with column_settings" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :table,
            attributes: %{
              column_settings: [
                %{align: "left", is_wrapped: true},
                %{align: "center", is_wrapped: false}
              ]
            },
            children: %{
              rows: [
                [
                  %{platform: :slack, element: :raw_text, attributes: %{text: "Name"}},
                  %{platform: :slack, element: :raw_text, attributes: %{text: "Role"}}
                ]
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "table",
                   rows: [
                     %{
                       cells: [
                         %{type: "raw_text", text: "Name"},
                         %{type: "raw_text", text: "Role"}
                       ]
                     }
                   ],
                   column_settings: [
                     %{align: "left", is_wrapped: true},
                     %{align: "center", is_wrapped: false}
                   ]
                 }
               ])
    end

    test "table block with rich_text cells" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :table,
            attributes: %{},
            children: %{
              rows: [
                [
                  %{
                    platform: :slack,
                    element: :rich_text,
                    children: %{
                      elements: [
                        %{
                          platform: :slack,
                          element: :rich_text_section,
                          attributes: %{},
                          children: %{
                            elements: [
                              %{
                                platform: :slack,
                                element: :text,
                                attributes: %{text: "Hello", style: %{bold: true}}
                              }
                            ]
                          }
                        }
                      ]
                    }
                  }
                ]
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "table",
                   rows: [
                     %{
                       cells: [
                         %{
                           type: "rich_text",
                           elements: [
                             %{
                               type: "rich_text_section",
                               elements: [
                                 %{type: "text", text: "Hello", style: %{bold: true}}
                               ]
                             }
                           ]
                         }
                       ]
                     }
                   ]
                 }
               ])
    end

    test "table block with block_id" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :table,
            attributes: %{block_id: "table_block_1"},
            children: %{
              rows: [
                [
                  %{platform: :slack, element: :raw_text, attributes: %{text: "Cell"}}
                ]
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "table",
                   rows: [
                     %{cells: [%{type: "raw_text", text: "Cell"}]}
                   ],
                   block_id: "table_block_1"
                 }
               ])
    end
  end

  describe "compile/1 with video" do
    test "video block with required fields" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :video,
            attributes: %{
              alt_text: "A demo video",
              title: "Demo",
              thumbnail_url: "https://example.com/thumb.png",
              video_url: "https://example.com/video.mp4"
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "video",
                   alt_text: "A demo video",
                   title: %{type: "plain_text", text: "Demo"},
                   thumbnail_url: "https://example.com/thumb.png",
                   video_url: "https://example.com/video.mp4"
                 }
               ])
    end

    test "video block with description and author_name" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :video,
            attributes: %{
              alt_text: "A demo video",
              title: "Demo",
              thumbnail_url: "https://example.com/thumb.png",
              video_url: "https://example.com/video.mp4",
              description: "A short demo of the feature",
              author_name: "Alice"
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "video",
                   alt_text: "A demo video",
                   title: %{type: "plain_text", text: "Demo"},
                   thumbnail_url: "https://example.com/thumb.png",
                   video_url: "https://example.com/video.mp4",
                   description: %{type: "plain_text", text: "A short demo of the feature"},
                   author_name: "Alice"
                 }
               ])
    end

    test "video block with title_url, provider_name, provider_icon_url" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :video,
            attributes: %{
              alt_text: "A demo video",
              title: "Demo",
              thumbnail_url: "https://example.com/thumb.png",
              video_url: "https://example.com/video.mp4",
              title_url: "https://example.com/page",
              provider_name: "Example",
              provider_icon_url: "https://example.com/icon.png"
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "video",
                   alt_text: "A demo video",
                   title: %{type: "plain_text", text: "Demo"},
                   thumbnail_url: "https://example.com/thumb.png",
                   video_url: "https://example.com/video.mp4",
                   title_url: "https://example.com/page",
                   provider_name: "Example",
                   provider_icon_url: "https://example.com/icon.png"
                 }
               ])
    end

    test "video block with deep title" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :video,
            attributes: %{
              alt_text: "A demo video",
              title: %{text: "Demo", emoji: true},
              thumbnail_url: "https://example.com/thumb.png",
              video_url: "https://example.com/video.mp4"
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "video",
                   alt_text: "A demo video",
                   title: %{type: "plain_text", text: "Demo", emoji: true},
                   thumbnail_url: "https://example.com/thumb.png",
                   video_url: "https://example.com/video.mp4"
                 }
               ])
    end

    test "video block with block_id" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :video,
            attributes: %{
              alt_text: "A demo video",
              title: "Demo",
              thumbnail_url: "https://example.com/thumb.png",
              video_url: "https://example.com/video.mp4",
              block_id: "video_block_1"
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "video",
                   alt_text: "A demo video",
                   title: %{type: "plain_text", text: "Demo"},
                   thumbnail_url: "https://example.com/thumb.png",
                   video_url: "https://example.com/video.mp4",
                   block_id: "video_block_1"
                 }
               ])
    end
  end

  describe "compile/1 with rich text inner elements" do
    alias Juvet.Template.Compiler.Slack.Objects.RichTextElement

    test "text element" do
      assert RichTextElement.compile(%{element: :text, attributes: %{text: "hello"}}) ==
               %{type: "text", text: "hello"}
    end

    test "text element with style" do
      assert RichTextElement.compile(%{
               element: :text,
               attributes: %{text: "bold", style: %{bold: true}}
             }) ==
               %{type: "text", text: "bold", style: %{bold: true}}
    end

    test "link element" do
      assert RichTextElement.compile(%{
               element: :link,
               attributes: %{url: "https://example.com"}
             }) ==
               %{type: "link", url: "https://example.com"}
    end

    test "link element with text, style, and unsafe" do
      assert RichTextElement.compile(%{
               element: :link,
               attributes: %{
                 url: "https://example.com",
                 text: "Example",
                 style: %{bold: true},
                 unsafe: true
               }
             }) ==
               %{
                 type: "link",
                 url: "https://example.com",
                 text: "Example",
                 style: %{bold: true},
                 unsafe: true
               }
    end

    test "emoji element" do
      assert RichTextElement.compile(%{element: :emoji, attributes: %{name: "wave"}}) ==
               %{type: "emoji", name: "wave"}
    end

    test "emoji element with unicode" do
      assert RichTextElement.compile(%{
               element: :emoji,
               attributes: %{name: "wave", unicode: "1f44b"}
             }) ==
               %{type: "emoji", name: "wave", unicode: "1f44b"}
    end

    test "channel element" do
      assert RichTextElement.compile(%{
               element: :channel,
               attributes: %{channel_id: "C123"}
             }) ==
               %{type: "channel", channel_id: "C123"}
    end

    test "channel element with style" do
      assert RichTextElement.compile(%{
               element: :channel,
               attributes: %{channel_id: "C123", style: %{bold: true}}
             }) ==
               %{type: "channel", channel_id: "C123", style: %{bold: true}}
    end

    test "user element" do
      assert RichTextElement.compile(%{element: :user, attributes: %{user_id: "U123"}}) ==
               %{type: "user", user_id: "U123"}
    end

    test "user element with style" do
      assert RichTextElement.compile(%{
               element: :user,
               attributes: %{user_id: "U123", style: %{italic: true}}
             }) ==
               %{type: "user", user_id: "U123", style: %{italic: true}}
    end

    test "usergroup element" do
      assert RichTextElement.compile(%{
               element: :usergroup,
               attributes: %{usergroup_id: "S123"}
             }) ==
               %{type: "usergroup", usergroup_id: "S123"}
    end

    test "usergroup element with style" do
      assert RichTextElement.compile(%{
               element: :usergroup,
               attributes: %{usergroup_id: "S123", style: %{bold: true}}
             }) ==
               %{type: "usergroup", usergroup_id: "S123", style: %{bold: true}}
    end

    test "date element" do
      assert RichTextElement.compile(%{
               element: :date,
               attributes: %{timestamp: 1_628_633_820, format: "{date_long}"}
             }) ==
               %{type: "date", timestamp: 1_628_633_820, format: "{date_long}"}
    end

    test "date element with url and fallback" do
      assert RichTextElement.compile(%{
               element: :date,
               attributes: %{
                 timestamp: 1_628_633_820,
                 format: "{date_long}",
                 url: "https://example.com",
                 fallback: "Aug 10, 2021"
               }
             }) ==
               %{
                 type: "date",
                 timestamp: 1_628_633_820,
                 format: "{date_long}",
                 url: "https://example.com",
                 fallback: "Aug 10, 2021"
               }
    end

    test "broadcast element" do
      assert RichTextElement.compile(%{element: :broadcast, attributes: %{range: "here"}}) ==
               %{type: "broadcast", range: "here"}
    end

    test "color element" do
      assert RichTextElement.compile(%{element: :color, attributes: %{value: "#FF5733"}}) ==
               %{type: "color", value: "#FF5733"}
    end
  end

  describe "compile/1 with rich text container elements" do
    test "rich_text_section with text elements" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_section,
                  attributes: %{},
                  children: %{
                    elements: [
                      %{platform: :slack, element: :text, attributes: %{text: "Hello "}},
                      %{
                        platform: :slack,
                        element: :link,
                        attributes: %{url: "https://example.com", text: "link"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [block] = result.blocks
      [section] = block.elements

      assert section == %{
               type: "rich_text_section",
               elements: [
                 %{type: "text", text: "Hello "},
                 %{type: "link", url: "https://example.com", text: "link"}
               ]
             }
    end

    test "rich_text_list with style and section items" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_list,
                  attributes: %{style: "ordered", indent: 1, offset: 0, border: 1},
                  children: %{
                    elements: [
                      %{
                        platform: :slack,
                        element: :rich_text_section,
                        attributes: %{},
                        children: %{
                          elements: [
                            %{platform: :slack, element: :text, attributes: %{text: "First"}}
                          ]
                        }
                      },
                      %{
                        platform: :slack,
                        element: :rich_text_section,
                        attributes: %{},
                        children: %{
                          elements: [
                            %{platform: :slack, element: :text, attributes: %{text: "Second"}}
                          ]
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [block] = result.blocks
      [list] = block.elements

      assert list == %{
               type: "rich_text_list",
               style: "ordered",
               indent: 1,
               offset: 0,
               border: 1,
               elements: [
                 %{
                   type: "rich_text_section",
                   elements: [%{type: "text", text: "First"}]
                 },
                 %{
                   type: "rich_text_section",
                   elements: [%{type: "text", text: "Second"}]
                 }
               ]
             }
    end

    test "rich_text_preformatted with text elements and border" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_preformatted,
                  attributes: %{border: 1},
                  children: %{
                    elements: [
                      %{platform: :slack, element: :text, attributes: %{text: "def hello"}}
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [block] = result.blocks
      [pre] = block.elements

      assert pre == %{
               type: "rich_text_preformatted",
               elements: [%{type: "text", text: "def hello"}],
               border: 1
             }
    end

    test "rich_text_quote with text elements and border" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_quote,
                  attributes: %{border: 0},
                  children: %{
                    elements: [
                      %{platform: :slack, element: :text, attributes: %{text: "A wise quote"}}
                    ]
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [block] = result.blocks
      [quote_el] = block.elements

      assert quote_el == %{
               type: "rich_text_quote",
               elements: [%{type: "text", text: "A wise quote"}],
               border: 0
             }
    end
  end

  describe "compile/1 with rich_text" do
    test "rich text block with rich_text_section containing styled text" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_section,
                  attributes: %{},
                  children: %{
                    elements: [
                      %{platform: :slack, element: :text, attributes: %{text: "Hello "}},
                      %{
                        platform: :slack,
                        element: :text,
                        attributes: %{text: "world", style: %{bold: true}}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "rich_text",
                   elements: [
                     %{
                       type: "rich_text_section",
                       elements: [
                         %{type: "text", text: "Hello "},
                         %{type: "text", text: "world", style: %{bold: true}}
                       ]
                     }
                   ]
                 }
               ])
    end

    test "rich text block with rich_text_list" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_list,
                  attributes: %{style: "bullet"},
                  children: %{
                    elements: [
                      %{
                        platform: :slack,
                        element: :rich_text_section,
                        attributes: %{},
                        children: %{
                          elements: [
                            %{platform: :slack, element: :text, attributes: %{text: "Item 1"}}
                          ]
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "rich_text",
                   elements: [
                     %{
                       type: "rich_text_list",
                       style: "bullet",
                       elements: [
                         %{
                           type: "rich_text_section",
                           elements: [%{type: "text", text: "Item 1"}]
                         }
                       ]
                     }
                   ]
                 }
               ])
    end

    test "rich text block with rich_text_preformatted" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_preformatted,
                  attributes: %{},
                  children: %{
                    elements: [
                      %{platform: :slack, element: :text, attributes: %{text: "code here"}}
                    ]
                  }
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "rich_text",
                   elements: [
                     %{
                       type: "rich_text_preformatted",
                       elements: [%{type: "text", text: "code here"}]
                     }
                   ]
                 }
               ])
    end

    test "rich text block with rich_text_quote" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_quote,
                  attributes: %{},
                  children: %{
                    elements: [
                      %{platform: :slack, element: :text, attributes: %{text: "quoted text"}}
                    ]
                  }
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "rich_text",
                   elements: [
                     %{
                       type: "rich_text_quote",
                       elements: [%{type: "text", text: "quoted text"}]
                     }
                   ]
                 }
               ])
    end

    test "rich text block with block_id" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{block_id: "rt_block_1"},
            children: %{
              elements: [
                %{
                  platform: :slack,
                  element: :rich_text_section,
                  attributes: %{},
                  children: %{
                    elements: [
                      %{platform: :slack, element: :text, attributes: %{text: "Hello"}}
                    ]
                  }
                }
              ]
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "rich_text",
                   elements: [
                     %{
                       type: "rich_text_section",
                       elements: [%{type: "text", text: "Hello"}]
                     }
                   ],
                   block_id: "rt_block_1"
                 }
               ])
    end

    test "rich text block with no children returns empty elements" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :rich_text,
            attributes: %{}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{type: "rich_text", elements: []}
               ])
    end
  end

  describe "compile/1 with markdown" do
    test "markdown block with text" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :markdown,
            attributes: %{text: "# Hello World\n\nSome **bold** text."}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{type: "markdown", text: "# Hello World\n\nSome **bold** text."}
               ])
    end

    test "markdown block with block_id" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :markdown,
            attributes: %{text: "Some text", block_id: "md_block_1"}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{type: "markdown", text: "Some text", block_id: "md_block_1"}
               ])
    end
  end

  describe "compile/1 with input" do
    test "input block with label and plain_text_input element" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :input,
            attributes: %{label: "Your Name"},
            children: %{
              element: %{
                platform: :slack,
                element: :plain_text_input,
                attributes: %{action_id: "name_input"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "input",
                   label: %{type: "plain_text", text: "Your Name"},
                   element: %{type: "plain_text_input", action_id: "name_input"}
                 }
               ])
    end

    test "input block with hint and optional" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :input,
            attributes: %{label: "Email", hint: "Enter your work email", optional: true},
            children: %{
              element: %{
                platform: :slack,
                element: :email_input,
                attributes: %{action_id: "email_input"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "input",
                   label: %{type: "plain_text", text: "Email"},
                   element: %{type: "email_text_input", action_id: "email_input"},
                   hint: %{type: "plain_text", text: "Enter your work email"},
                   optional: true
                 }
               ])
    end

    test "input block with dispatch_action and block_id" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :input,
            attributes: %{
              label: "Search",
              dispatch_action: true,
              block_id: "input_block_1"
            },
            children: %{
              element: %{
                platform: :slack,
                element: :plain_text_input,
                attributes: %{action_id: "search_input"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "input",
                   label: %{type: "plain_text", text: "Search"},
                   element: %{type: "plain_text_input", action_id: "search_input"},
                   dispatch_action: true,
                   block_id: "input_block_1"
                 }
               ])
    end

    test "input block with deep label" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :input,
            attributes: %{label: %{text: "Your Name", emoji: true}},
            children: %{
              element: %{
                platform: :slack,
                element: :plain_text_input,
                attributes: %{action_id: "name_input"}
              }
            }
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "input",
                   label: %{type: "plain_text", text: "Your Name", emoji: true},
                   element: %{type: "plain_text_input", action_id: "name_input"}
                 }
               ])
    end
  end

  describe "compile/1 with file" do
    test "file block with external_id and source" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :file,
            attributes: %{external_id: "ABCD1", source: "remote"}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{type: "file", external_id: "ABCD1", source: "remote"}
               ])
    end

    test "file block with block_id" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :file,
            attributes: %{external_id: "ABCD1", source: "remote", block_id: "file_block_1"}
          }
        ])

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "file",
                   external_id: "ABCD1",
                   source: "remote",
                   block_id: "file_block_1"
                 }
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

  describe "compile/1 with confirmation dialog" do
    test "confirmation dialog with all required fields" do
      result =
        Juvet.Template.Compiler.Slack.Objects.ConfirmationDialog.compile(%{
          element: :confirm,
          attributes: %{
            title: "Are you sure?",
            text: "This action cannot be undone.",
            confirm: "Yes, do it",
            deny: "Cancel"
          }
        })

      assert result == %{
               title: %{type: "plain_text", text: "Are you sure?"},
               text: %{type: "plain_text", text: "This action cannot be undone."},
               confirm: %{type: "plain_text", text: "Yes, do it"},
               deny: %{type: "plain_text", text: "Cancel"}
             }
    end

    test "confirmation dialog with optional style" do
      result =
        Juvet.Template.Compiler.Slack.Objects.ConfirmationDialog.compile(%{
          element: :confirm,
          attributes: %{
            title: "Confirm",
            text: "Are you sure?",
            confirm: "Yes",
            deny: "No",
            style: "danger"
          }
        })

      assert result.style == "danger"
    end

    test "button with confirm child" do
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
                  attributes: %{text: "Delete", action_id: "delete_btn"},
                  children: %{
                    confirm: %{
                      element: :confirm,
                      attributes: %{
                        title: "Are you sure?",
                        text: "This will delete the item.",
                        confirm: "Delete",
                        deny: "Cancel",
                        style: "danger"
                      }
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [button] = actions.elements

      assert button.confirm == %{
               title: %{type: "plain_text", text: "Are you sure?"},
               text: %{type: "plain_text", text: "This will delete the item."},
               confirm: %{type: "plain_text", text: "Delete"},
               deny: %{type: "plain_text", text: "Cancel"},
               style: "danger"
             }
    end

    test "checkboxes with confirm child" do
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
                  element: :checkboxes,
                  attributes: %{action_id: "chk_1"},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Option 1", value: "opt_1"}
                      }
                    ],
                    confirm: %{
                      element: :confirm,
                      attributes: %{
                        title: "Confirm",
                        text: "Change selection?",
                        confirm: "Yes",
                        deny: "No"
                      }
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [checkboxes] = actions.elements

      assert checkboxes.confirm == %{
               title: %{type: "plain_text", text: "Confirm"},
               text: %{type: "plain_text", text: "Change selection?"},
               confirm: %{type: "plain_text", text: "Yes"},
               deny: %{type: "plain_text", text: "No"}
             }
    end

    test "select with confirm child" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :select,
                attributes: %{source: :static, action_id: "sel_1"},
                children: %{
                  options: [
                    %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Option 1", value: "opt_1"}
                    }
                  ],
                  confirm: %{
                    element: :confirm,
                    attributes: %{
                      title: "Confirm",
                      text: "Select this?",
                      confirm: "Yes",
                      deny: "No"
                    }
                  }
                }
              }
            }
          }
        ])

      result = Slack.compile(ast)
      [section] = result.blocks

      assert section.accessory.confirm == %{
               title: %{type: "plain_text", text: "Confirm"},
               text: %{type: "plain_text", text: "Select this?"},
               confirm: %{type: "plain_text", text: "Yes"},
               deny: %{type: "plain_text", text: "No"}
             }
    end

    test "datepicker with confirm child" do
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
                  element: :datepicker,
                  attributes: %{action_id: "date_1"},
                  children: %{
                    confirm: %{
                      element: :confirm,
                      attributes: %{
                        title: "Confirm Date",
                        text: "Use this date?",
                        confirm: "Yes",
                        deny: "No"
                      }
                    }
                  }
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [datepicker] = actions.elements

      assert datepicker.confirm == %{
               title: %{type: "plain_text", text: "Confirm Date"},
               text: %{type: "plain_text", text: "Use this date?"},
               confirm: %{type: "plain_text", text: "Yes"},
               deny: %{type: "plain_text", text: "No"}
             }
    end
  end
end
