defmodule Juvet.SlackViewStateTest do
  use ExUnit.Case, async: true

  alias Juvet.SlackViewState

  describe "parse/1" do
    test "returns a map of keys and values parsed from Slack's conversation select" do
      view_state = %{
        "block_id" => %{
          "conversation_select_name" => %{
            "selected_conversation" => "C12345",
            "type" => "conversations_select"
          }
        }
      }

      assert SlackViewState.parse(view_state) == %{
               "conversation_select_name" => "C12345"
             }
    end

    test "returns a map of keys and values parsed from Slack's plain text value" do
      view_state = %{
        "block_id" => %{
          "plain_text_field" => %{
            "value" => "Hello world",
            "type" => "plain_text"
          }
        }
      }

      assert SlackViewState.parse(view_state) == %{
               "plain_text_field" => "Hello world"
             }
    end

    test "returns a map of keys and values parsed from Slack's form" do
      view_state = %{
        "block_id_1" => %{
          "menu_field" => %{
            "selected_option" => %{
              "text" => %{
                "type" => "plain_text",
                "text" => "Selected value"
              },
              "value" => "selected_value"
            },
            "type" => "static_select"
          }
        },
        "block_id_2" => %{
          "checkboxes_field" => %{
            "selected_options" => [
              %{
                "text" => %{
                  "type" => "plain_text",
                  "text" => "Selected value"
                },
                "value" => "selected_value"
              }
            ],
            "type" => "checkboxes"
          }
        }
      }

      assert SlackViewState.parse(view_state) == %{
               "menu_field" => "selected_value",
               "checkboxes_field" => ["selected_value"]
             }
    end

    test "handles multiple fields under one block" do
      view_state = %{
        "block_id_1" => %{
          "field1" => %{
            "selected_option" => %{
              "text" => %{
                "type" => "plain_text",
                "text" => "Selected value"
              },
              "value" => "selected_value"
            },
            "type" => "static_select"
          },
          "field2" => %{
            "selected_date" => "2020-01-04",
            "type" => "datepicker"
          }
        }
      }

      assert SlackViewState.parse(view_state) == %{
               "field1" => "selected_value",
               "field2" => "2020-01-04"
             }
    end
  end
end
