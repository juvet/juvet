defmodule Juvet.Router.PlatformFactoryTest do
  use ExUnit.Case, async: true

  describe "Juvet.Router.PlatformFactory.new/1" do
    test "returns a SlackPlatform when the platform is slack" do
      assert Juvet.Router.SlackPlatform ==
               Juvet.Router.PlatformFactory.new(:slack)
    end

    test "returns an UnknownFactory when the platform is not recognized" do
      assert Juvet.Router.UnknownPlatform ==
               Juvet.Router.PlatformFactory.new(:blah)
    end
  end
end
