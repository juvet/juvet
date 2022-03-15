defmodule Juvet.SlackFormValuesTest do
  use ExUnit.Case, async: true

  alias Juvet.SlackFormValues

  describe "values/1" do
    test "returns a map of keys and values parsed from Slack's conversation select" do
      slack_form_values = %{
        "block_id" => %{
          "conversation_select_name" => %{
            "selected_conversation" => "C12345",
            "type" => "conversations_select"
          }
        }
      }

      assert SlackFormValues.form_values(slack_form_values) == %{
               "conversation_select_name" => "C12345"
             }
    end

    test "returns a map of keys and values parsed from Slack's plain text value" do
      slack_form_values = %{
        "block_id" => %{
          "plain_text_field" => %{
            "value" => "Hello world",
            "type" => "plain_text"
          }
        }
      }

      assert SlackFormValues.form_values(slack_form_values) == %{
               "plain_text_field" => "Hello world"
             }
    end

    test "returns a map of keys and values parsed from Slack's form" do
      slack_form_values = %{
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

      assert SlackFormValues.form_values(slack_form_values) == %{
               "menu_field" => "selected_value",
               "checkboxes_field" => ["selected_value"]
             }
    end
  end
end
