defmodule Juvet.GregorianDateTime do
  # TODO: Could use Elixir native methods if runtime is uopdated: https://hexdocs.pm/elixir/1.13.1/DateTime.html#from_gregorian_seconds/3
  @unix_gregorian_offset 62_167_219_200

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
