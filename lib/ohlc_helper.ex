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

  @deprecated "OHLCFactory.gen_empty_candle/1 instead. Will be removed in v2.x."
  @doc """
  Generates and returns empty candle.

  If provided with timeframe stime and etime will be
  generated based on current time.
  """
  @spec generate_empty_candle(OHLC.timeframe() | nil) :: OHLC.candle()
  def generate_empty_candle(timeframe \\ nil) do
    OHLCFactory.gen_empty_candle(timeframe)
  end

  @doc """
  Helper function for formatting the value to float.
  """
  @spec format_to_float(any) :: float | false
  def format_to_float(value) when is_binary(value) do
    {float, _} = value |> String.replace(",", ".") |> String.trim() |> Float.parse()
    float
  end

  def format_to_float(value) when is_number(value) or is_integer(value), do: value / 1
  def format_to_float(value) when is_float(value), do: value
  def format_to_float(_), do: false

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
  @spec get_time_rounded(number(), OHLC.timeframe(), list() | nil) :: number() | %DateTime{}
  def get_time_rounded(timestamp, timeframe, opts \\ []) do
    timestamp = timestamp |> format_to_float() |> round()

    {:ok, time_struct} = DateTime.from_unix(timestamp)

    candle_time = %DateTime{
      year: 00,
      month: 00,
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

  @deprecated "Use OHLCFactory.gen_trades/1 instead. Will be removed in v2.x."
  @doc """
  Generates trades from provided arguments.

  Parameters:
  - `timeframe` - Timeframe used for rounding the timestamp.
  Available values are: `:minute`, `:hour`, `:day`, `:week`
  - `min_price` - The minimum price on the generated trades
  - `max_price` - The maximum price on the generated trades
  - `volume` - The volume each trade has
  - `timeframe_multiplier` - If you'd like to generate less trades per candle then you can increase the size of
  the timeframe_divider parameter(1-100) otherwise leave empty.
  - `timeframe_divider` - Is used for generating multiple candles of the same timeframe.
  """
  @spec gen_trades(OHLC.timeframe(), number(), number(), number(), integer(), integer()) :: list()
  def gen_trades(
        timeframe,
        min_price,
        max_price,
        volume,
        timeframe_multiplier \\ 1,
        timeframe_divider \\ 1
      ) do
    OHLCFactory.gen_trades(
      timeframe: timeframe,
      min_price: min_price,
      max_price: max_price,
      volume: volume,
      timeframe_multiplier: timeframe_multiplier,
      timeframe_divider: timeframe_divider
    )
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
  @spec validate_data(OHLC.candles() | nil, OHLC.trades() | nil) :: :ok | {:error, atom()}
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

    cond do
      opts[:type] === :down ->
        Date.beginning_of_week(time_struct)
        |> Map.put(:second, 00)
        |> Map.put(:minute, 00)
        |> Map.put(:hour, 00)

      opts[:type] === :up or opts[:type] === nil ->
        Date.end_of_week(time_struct)
        |> Map.put(:second, 59)
        |> Map.put(:minute, 59)
        |> Map.put(:hour, 23)

      opts[:type] === :jump ->
        DateTime.add(time_struct, timeframe_secs, :second)
        |> Date.beginning_of_week()
        |> Map.put(:second, 00)
        |> Map.put(:minute, 00)
        |> Map.put(:hour, 00)
    end
    |> set_worked_time(unfinished_time_struct)
  end

  defp set_worked_time(worked_timestruct, def_timestruct) do
    %{
      def_timestruct
      | year: worked_timestruct.year,
        month: worked_timestruct.month,
        day: worked_timestruct.day,
        hour: worked_timestruct.hour,
        minute: worked_timestruct.minute,
        second: worked_timestruct.second
    }
  end

  defp validate_candles(candles) do
    empty_candle = OHLCFactory.gen_empty_candle()

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
      {:error, :candle_invalid}
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
        {:error, :invalid_trades}
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
        {:error, :invalid_price}

      !volume_validation ->
        {:error, :invalid_volume}

      !time_validation ->
        {:error, :invalid_time}

      !etime_greater ->
        {:error, :invalid_candle_order}

      true ->
        :ok
    end
  end
end
