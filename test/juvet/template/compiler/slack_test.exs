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
