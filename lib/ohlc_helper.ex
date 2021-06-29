defmodule OHLCHelper do
  @moduledoc """
  OHLC Helper module containing all the helper functions.
  """

  @timeframes [minute: 60, hour: 3600, day: 86_400, week: 604_800]

  @doc """
  Returns all available timeframes in seconds.
  """
  @spec get_timeframes() :: list()
  def get_timeframes() do
    @timeframes
  end

  @doc """
  Generates and returns empty candle.

  If provided with timeframe stime and etime will be
  generated based on current time.
  """
  @spec generate_empty_candle(OHLC.timeframe() | nil) :: OHLC.candle()
  def generate_empty_candle(timeframe \\ nil) do
    {stime, etime} =
      case timeframe do
        nil ->
          {0, 0}

        _ ->
          curr_timestamp =
            DateTime.utc_now()
            |> DateTime.to_unix()

          {
            get_time_rounded(curr_timestamp, timeframe, type: :down),
            get_time_rounded(curr_timestamp, timeframe, type: :up)
          }
      end

    %{
      :open => 0,
      :high => 0,
      :low => 0,
      :close => 0,
      :volume => 0,
      :trades => 0,
      :stime => stime,
      :etime => etime,
      :type => nil,
      :processed => false
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

  Parameters:
  - `timestamp` - Unix timestamp which will be rounded.
  - `timeframe` - Timeframe used for rounding the timestamp.
  Available values are: `:minute`, `:hour`, `:day`, `:week`
  - `opts` - Options for rounding the timestamp.
  Available values are:
    - `{:format, :stamp | :struct}` - Returned value will be
    unix timestamp or DateTime struct.
    - `{:type, :down | :up | :jump}` - Timestamp will be rounded
    up, down or jump to the next time cycle. Default is `:up`.
  """
  @spec get_time_rounded(number(), OHLC.timeframe(), list() | nil) :: number() | DateTime
  def get_time_rounded(timestamp, timeframe, opts \\ []) do
    timestamp = timestamp |> format_to_float() |> round()

    {:ok, time_struct} = DateTime.from_unix(timestamp)

    candle_time = %DateTime{
      year: time_struct.year,
      month: time_struct.month,
      day: 00,
      hour: 00,
      minute: 00,
      second: 00,
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
      _ -> DateTime.to_unix(rounded_time)
    end
  end

  @doc """
  Calculates the total volume from trades.
  """
  @spec trades_total_volume(OHLC.trades()) :: float
  def trades_total_volume(trades) do
    Enum.reduce(trades, fn trade, acc ->
      volume_formatted = format_to_float(trade[:volume])

      if is_float(acc) do
        acc + volume_formatted
      else
        format_to_float(acc[:volume]) + volume_formatted
      end
    end)
    |> Float.round(4)
  end

  @doc """
  Gets the current candle type(pullish or bearish).

  Returns
  `:bullish` - if close price > open price.
  `bearish` - if previous close price <= open price.
  """
  @spec get_candle_type(number(), number()) :: :bullish | :bearish
  def get_candle_type(open, close) do
    type = if close > open, do: :bullish, else: :bearish

    type
  end

  @doc """
  Validates the data used for generating the OHLC candles.
  Accepts lists of candles, trades or both.
  """
  @spec validate_data(OHLC.candles() | nil, OHLC.trades() | nil) :: :ok | {:error, binary()}
  def validate_data(candles \\ [], trades \\ []) do
    case validate_candles(candles) do
      {:error, candles_error_msg} ->
        {:error, candles_error_msg}

      :ok ->
        trades_validated = validate_trades(trades)

        case trades_validated do
          {:error, trades_error_msg} -> {:error, trades_error_msg}
          :ok -> :ok
        end
    end
  end

  defp time_minute_worker(time_struct, unfinished_time_struct, opts) do
    timeframe_secs = get_timeframes()[:minute]

    cond do
      opts[:type] === :down ->
        Map.put(time_struct, :second, 00)

      opts[:type] === :up or opts[:type] === nil ->
        Map.put(time_struct, :second, 59)

      opts[:type] === :jump ->
        DateTime.add(time_struct, timeframe_secs, :second) |> Map.put(:second, 00)
    end
    |> set_worked_time(unfinished_time_struct)
  end

  defp time_hour_worker(time_struct, unfinished_time_struct, opts) do
    timeframe_secs = get_timeframes()[:hour]

    cond do
      opts[:type] === :down ->
        Map.put(time_struct, :second, 00) |> Map.put(:minute, 00)

      opts[:type] === :up or opts[:type] === nil ->
        Map.put(time_struct, :second, 59) |> Map.put(:minute, 59)

      opts[:type] === :jump ->
        DateTime.add(time_struct, timeframe_secs, :second)
        |> Map.put(:second, 00)
        |> Map.put(:minute, 00)
    end
    |> set_worked_time(unfinished_time_struct)
  end

  defp time_day_worker(time_struct, unfinished_time_struct, opts) do
    timeframe_secs = get_timeframes()[:day]

    cond do
      opts[:type] === :down ->
        Map.put(time_struct, :second, 00) |> Map.put(:minute, 00) |> Map.put(:hour, 00)

      opts[:type] === :up or opts[:type] === nil ->
        Map.put(time_struct, :second, 59) |> Map.put(:minute, 59) |> Map.put(:hour, 23)

      opts[:type] === :jump ->
        DateTime.add(time_struct, timeframe_secs, :second)
        |> Map.put(:second, 00)
        |> Map.put(:minute, 00)
        |> Map.put(:hour, 00)
    end
    |> set_worked_time(unfinished_time_struct)
  end

  defp time_week_worker(time_struct, unfinished_time_struct, opts) do
    timeframe_secs = get_timeframes()[:week]
    day_of_week = DateTime.to_date(time_struct) |> Date.day_of_week()
    days_to_calc = 7 - day_of_week

    time_struct = DateTime.add(time_struct, get_timeframes()[:day] * days_to_calc, :second)

    cond do
      opts[:type] === :down ->
        DateTime.add(time_struct, -(get_timeframes()[:day] * 7), :second)
        |> Map.put(:second, 00)
        |> Map.put(:minute, 00)
        |> Map.put(:hour, 00)

      opts[:type] === :up or opts[:type] === nil ->
        Map.put(time_struct, :second, 59) |> Map.put(:minute, 59) |> Map.put(:hour, 23)

      opts[:type] === :jump ->
        DateTime.add(time_struct, timeframe_secs, :second)
        |> Map.put(:second, 00)
        |> Map.put(:minute, 00)
        |> Map.put(:hour, 00)
    end
    |> set_worked_time(unfinished_time_struct)
  end

  defp set_worked_time(worked_timestruct, def_timestruct) do
    %{
      def_timestruct
      | month: worked_timestruct.month,
        day: worked_timestruct.day,
        hour: worked_timestruct.hour,
        minute: worked_timestruct.minute,
        second: worked_timestruct.second
    }
  end

  defp validate_candles(candles) do
    empty_candle = generate_empty_candle()

    data_validated =
      Enum.all?(candles, fn candle ->
        if is_map(candle) do
          Enum.all?(empty_candle, fn el ->
            Map.has_key?(candle, el |> elem(0))
          end)
        else
          false
        end
      end)

    if data_validated do
      :ok
    else
      {:error, "Candles must be type of map containing all the neccessary keys."}
    end
  end

  defp validate_trades(trades, prev_etime \\ nil)

  defp validate_trades([trades_head | trades_body], prev_etime) do
    trade_fields = [:price, :volume, :time]

    keys_validated = Enum.all?(trade_fields, &trades_head[&1])

    case keys_validated do
      true ->
        trade_data_validated = validate_trade_data(trades_head, prev_etime)

        case trade_data_validated do
          :ok -> validate_trades(trades_body, trades_head[:time])
          {:error, msg} -> {:error, msg}
        end

      false ->
        {:error, "Trades list does not contain all necessary keys"}
    end
  end

  defp validate_trades([], _prev_etime) do
    :ok
  end

  defp validate_trade_data(trade, prev_etime) do
    price_validation = is_float(format_to_float(trade[:price]))
    volume_validation = is_float(format_to_float(trade[:volume]))
    time_validation = is_float(format_to_float(trade[:time]))

    etime_greater =
      cond do
        prev_etime === nil -> true
        time_validation -> format_to_float(trade[:time]) >= format_to_float(prev_etime) || false
        true -> false
      end

    cond do
      !price_validation ->
        {:error, "Price is not float: #{format_to_float(trade[:price])}"}

      !volume_validation ->
        {:error, "Volume is not float: #{format_to_float(trade[:volume])}"}

      !time_validation ->
        {:error, "Time is not float: #{format_to_float(trade[:volume])}"}

      !etime_greater ->
        {:error,
         "Current trade time(#{format_to_float(trade[:time])}) is not bigger or equal to the previous trade time(#{format_to_float(prev_etime)})"}

      true ->
        :ok
    end
  end
end
