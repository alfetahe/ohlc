defmodule OHLCHelper do
  @moduledoc """
    OHLC Helper module containing all helper functions.
  """

  @doc """
  Generates empty candle.
  """
  @spec generate_empty_candle :: map()
  def generate_empty_candle() do
    %{
      "etime" => 0,
      "stime" => 0,
      "open" => 0,
      "high" => 0,
      "low" => 0,
      "close" => 0,
      "volume" => 0,
      "trades" => 0,
      "processed" => false
    }
  end

  @doc """
  Helper function for formatting the value to float.
  """
  @spec format_to_float(any) :: float | {:error, binary()}
  def format_to_float(value) when is_binary(value) do
    {float, _} = value |> String.replace(",", ".") |> String.trim() |> Float.parse()
    float
  end

  def format_to_float(value) when is_number(value) or is_integer(value), do: value / 1
  def format_to_float(value) when is_float(value), do: value
  def format_to_float(value), do: {:error, "Data not formattable to float: #{value}"}

  @doc """
  Gets the rounded timestamp based on the timeframe.
  """
  def get_time_rounded(timestamp, timeframe, opts \\ []) do
    timestamp = timestamp |> format_to_float() |> round()

    {:ok, time_struct} = DateTime.from_unix(timestamp)

    candle_time = %DateTime{
      year: time_struct.year,
      month: time_struct.month,
      day: 0,
      hour: 0,
      minute: 0,
      second: 0,
      time_zone: time_struct.time_zone,
      zone_abbr: time_struct.zone_abbr,
      utc_offset: time_struct.utc_offset,
      std_offset: time_struct.std_offset
    }

    rounded_time =
      case timeframe do
        :minute -> time_minute_worker(time_struct, candle_time, opts)
        :hour -> time_hour_worker(time_struct, candle_time, opts)
        :day -> time_day_worker(time_struct, candle_time, opts)
        :week -> time_week_worker(time_struct, candle_time, opts)
      end

    case opts[:format] do
      :stamp -> DateTime.to_unix(rounded_time)
      :struct -> rounded_time
      nil -> DateTime.to_unix(rounded_time)
    end
  end

  defp time_minute_worker(time_struct, unfinished_time_struct, opts) do
    worked_time_struct =
      if time_struct.second === 0 do
        time_struct
      else
        DateTime.add(time_struct, 60, :second)
      end

    worked_time_struct =
      case opts[:type] do
        :start -> DateTime.add(worked_time_struct, -60, :second)
        :end -> DateTime.add(worked_time_struct, 60, :second)
        nil -> worked_time_struct
      end

    %{
      unfinished_time_struct
      | day: worked_time_struct.day,
        hour: worked_time_struct.hour,
        minute: worked_time_struct.minute,
        second: 0
    }
  end

  defp time_hour_worker(time_struct, unfinished_time_struct, opts) do
    worked_time_struct =
      if time_struct.second === 0 and time_struct.minute === 0 do
        time_struct
      else
        DateTime.add(time_struct, 3600, :second)
      end

    worked_time_struct =
      case opts[:type] do
        :end -> DateTime.add(worked_time_struct, 3600, :second)
        :start -> DateTime.add(worked_time_struct, -3600, :second)
        nil -> worked_time_struct
      end

    %{
      unfinished_time_struct
      | day: worked_time_struct.day,
        hour: worked_time_struct.hour,
        minute: 00,
        second: 00
    }
  end

  defp time_day_worker(time_struct, unfinished_time_struct, opts) do
    worked_time_struct =
      if time_struct.second === 0 and time_struct.minute === 0 and time_struct.hour === 0 do
        time_struct
      else
        DateTime.add(time_struct, 86_400, :second)
      end

    worked_time_struct =
      case opts[:type] do
        :end -> DateTime.add(worked_time_struct, 86_400, :second)
        :start -> DateTime.add(worked_time_struct, -86_400, :second)
        nil -> worked_time_struct
      end

    %{unfinished_time_struct | day: worked_time_struct.day, hour: 0, minute: 0, second: 0}
  end

  defp time_week_worker(time_struct, unfinished_time_struct, opts) do
    day_of_week = DateTime.to_date(time_struct) |> Date.day_of_week()
    days_to_calc = 7 - day_of_week + 1

    worked_time_struct =
      if time_struct.second === 0 and time_struct.minute === 0 and time_struct.hour === 0 and
            days_to_calc === 7 do
        time_struct
      else
        DateTime.add(time_struct, 86_400 * days_to_calc, :second)
      end

    worked_time_struct =
      case opts[:type] do
        :end -> DateTime.add(worked_time_struct, 604_800, :second)
        :start -> DateTime.add(worked_time_struct, -604_800, :second)
        nil -> worked_time_struct
      end

    %{
      unfinished_time_struct
      | month: worked_time_struct.month,
        day: worked_time_struct.day,
        hour: 0,
        minute: 0,
        second: 0
    }
  end
end
