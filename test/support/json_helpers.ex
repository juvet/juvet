defmodule Juvet.Test.JsonHelpers do
  @moduledoc false

  def json_equal?(json_string, expected_map) do
    Poison.decode!(json_string) == expected_map
  end
end
