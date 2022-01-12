defmodule Juvet.GregorianDateTimeTest do
  use ExUnit.Case, async: true

  alias Juvet.GregorianDateTime

  describe "to_seconds/1" do
    test "returns the provided timestamp to Gregorian seconds" do
      {:ok, date_time} = NaiveDateTime.new(~D[2021-04-04], ~T[23:04:07])

      assert 1_617_577_447 = GregorianDateTime.to_seconds(date_time)
    end
  end
end
