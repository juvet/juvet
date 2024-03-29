defmodule Juvet.GregorianDateTime do
  @moduledoc """
  Module to work with `NaiveDateTime` and convert to a gregorian date.
  """

  @unix_gregorian_offset 62_167_219_200

  @doc """
  This calculates the number of seconds for a specific `NaiveDateTime`.
  """
  @spec to_seconds(NaiveDateTime.t()) :: integer()
  def to_seconds(date_time \\ NaiveDateTime.utc_now()) do
    timestamp =
      date_time
      |> convert_to_calendar()
      |> :calendar.datetime_to_gregorian_seconds()

    timestamp - @unix_gregorian_offset
  end

  defp convert_to_calendar(%NaiveDateTime{} = date_time),
    do: date_time |> NaiveDateTime.to_erl()
end
