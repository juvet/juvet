defmodule Juvet.TemplateTest do
  use ExUnit.Case, async: true

  alias Juvet.Template

  describe "render/1" do
    # We are not here yet
    @tag :skip
    test "empty template returns empty string" do
      assert Template.render("") == ""
    end
  end

  describe "render/2" do
    # This may or may not be a valid case
    @tag :skip
    test "simple evaluation within template returns evaluated string" do
      assert Template.render("<%= salutation %>", salutation: "Hello there") == "Hello there"
    end
  end
end
