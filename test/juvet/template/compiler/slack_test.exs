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
                element: :static_select,
                attributes: %{action_id: "sel_1"},
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
                element: :static_select,
                attributes: %{action_id: "sel_1"},
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
                element: :static_select,
                attributes: %{action_id: "sel_1"},
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

  describe "compile/1 with static_select" do
    test "basic static_select with options" do
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
                  element: :static_select,
                  attributes: %{action_id: "sel_1"},
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

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "actions",
                   elements: [
                     %{
                       type: "static_select",
                       action_id: "sel_1",
                       options: [
                         %{text: %{type: "plain_text", text: "Option 1"}, value: "opt_1"},
                         %{text: %{type: "plain_text", text: "Option 2"}, value: "opt_2"}
                       ]
                     }
                   ]
                 }
               ])
    end

    test "static_select with placeholder" do
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
                  element: :static_select,
                  attributes: %{action_id: "sel_1", placeholder: "Choose an option"},
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

      assert select.placeholder == %{type: "plain_text", text: "Choose an option"}
    end

    test "static_select with action_id" do
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
                  element: :static_select,
                  attributes: %{action_id: "my_select"},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Opt", value: "v"}
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

      assert select.action_id == "my_select"
    end

    test "static_select with option_groups instead of options" do
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
                  element: :static_select,
                  attributes: %{action_id: "sel_1"},
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
                              attributes: %{text: "A", value: "a"}
                            }
                          ]
                        }
                      },
                      %{
                        platform: :slack,
                        element: :option_group,
                        attributes: %{label: "Group 2"},
                        children: %{
                          options: [
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
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select.option_groups == [
               %{
                 label: %{type: "plain_text", text: "Group 1"},
                 options: [%{text: %{type: "plain_text", text: "A"}, value: "a"}]
               },
               %{
                 label: %{type: "plain_text", text: "Group 2"},
                 options: [%{text: %{type: "plain_text", text: "B"}, value: "b"}]
               }
             ]

      refute Map.has_key?(select, :options)
    end

    test "static_select with initial_option" do
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
                  element: :static_select,
                  attributes: %{action_id: "sel_1"},
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
                    initial_option: %{
                      platform: :slack,
                      element: :option,
                      attributes: %{text: "Option 1", value: "opt_1"}
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
               text: %{type: "plain_text", text: "Option 1"},
               value: "opt_1"
             }
    end

    test "static_select with focus_on_load" do
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
                  element: :static_select,
                  attributes: %{action_id: "sel_1", focus_on_load: true},
                  children: %{
                    options: [
                      %{
                        platform: :slack,
                        element: :option,
                        attributes: %{text: "Opt", value: "v"}
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

      assert select.focus_on_load == true
    end

    test "static_select with no options" do
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
                  element: :static_select,
                  attributes: %{action_id: "sel_1"}
                }
              ]
            }
          }
        ])

      result = Slack.compile(ast)
      [actions] = result.blocks
      [select] = actions.elements

      assert select == %{type: "static_select", action_id: "sel_1"}
    end

    test "static_select as section accessory" do
      ast =
        view_ast([
          %{
            platform: :slack,
            element: :section,
            attributes: %{text: "Pick one"},
            children: %{
              accessory: %{
                platform: :slack,
                element: :static_select,
                attributes: %{action_id: "sel_1", placeholder: "Choose"},
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

      assert Slack.compile(ast) ==
               view_expected([
                 %{
                   type: "section",
                   text: %{type: "mrkdwn", text: "Pick one"},
                   accessory: %{
                     type: "static_select",
                     action_id: "sel_1",
                     placeholder: %{type: "plain_text", text: "Choose"},
                     options: [
                       %{text: %{type: "plain_text", text: "Option 1"}, value: "opt_1"}
                     ]
                   }
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
