defmodule Juvet.RouterTest do
  use ExUnit.Case, async: true

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      command("/test", to: "controller#action")
    end
  end

  describe "Juvet.Router.platform/2" do
    test "accumulates the platforms within the router" do
      platforms = Juvet.Router.platforms(MyRouter)

      assert Enum.count(platforms) == 1
      assert List.first(platforms).platform == :slack
    end
  end
end
