defmodule Juvet.TemplateTest do
  use ExUnit.Case, async: true

  alias Juvet.Template

  describe "render/1" do
    test "empty template returns empty string" do
      assert Template.render("") == ""
    end
  end

  describe "render/2" do
    test "simple evaluation within template returns evaluated string" do
      assert Template.render("<%= salutation %>", salutation: "Hello there") == "Hello there"
    end
  end
end
