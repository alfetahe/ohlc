defmodule Candloo do
  @moduledoc """
  Documentation for Candloo.
  """

  alias Candloo.Candle

  @no_trades_skip_candle :skip
  @no_trades_copy_last_close :copy_last_close

  @doc """
  Creates OHLC candles from trades.
  """
  def create_candles(
        [[{:price, _}, {:volume, _}, {:time, _}, {:side, _}] | _] = trades,
        timeframe,
        opts \\ []
      ) do

    no_trade_options = [@no_trades_skip_candle, @no_trades_copy_last_close]
    no_trade_option = if (Enum.member?(no_trade_options, opts[:no_trades])) do
      opts[:no_trades]
    else
      # By default were coping the last candles close price if no trades in interval.
      @no_trades_copy_last_close
    end

    loop_trades(trades, [%Candle{}], timeframe, no_trade_option)
  end

  # Loops thru trades and creates or updates candles.
  defp loop_trades(
         [trades_head | trades_tail] = trades,
         [candles_head | candles_body] = candles,
         timeframe,
         no_trade_option
  ) do
    candle_in_timeframe = timeframe_has_candle?(candles_head, trades_head)

    candles =
      cond do
        # Appends new candle to the candles list without the unprocessed candle.
        !candles_head.processed ->
          candle = create_candle(trades_head, timeframe)
          [candle] ++ candles_body

        # Updates last candle.
        candle_in_timeframe ->
          updated_candle = update_candle(candles_head, trades_head)
          [updated_candle] ++ candles_body

        # Creates new candle or candles.
        !candle_in_timeframe ->
          case no_trade_option do
            @no_trades_copy_last_close ->
              copied_candles = copy_last_price_loop(candles_head, trades, timeframe, [])
              copied_candles ++ candles
            @no_trades_skip_candle ->
              candle = create_candle(trades_head, timeframe)
              [candle] ++ candles
          end
      end

    loop_trades(trades_tail, candles, timeframe, no_trade_option)
  end

  # Returns all candles.
  defp loop_trades(trades, candles, _timeframe, _no_trade_option) when length(trades) == 0, do: candles

  defp copy_last_price_loop(last_candle, [trades_head | trades_tail], timeframe, worked_candles) do

    trade_stime = get_time_added(timeframe, trades_head[:time], [format: :struct])
    last_candle_etime = get_time_added(timeframe, Map.get(last_candle, :etime), [format: :struct])

    if (first_date_greater?(trade_stime, last_candle_etime)) do
      copied_candle = get_empty_candle(
        last_candle[:close],
        get_time_added(timeframe, last_candle_etime),
        get_time_added(timeframe, last_candle_etime)
      )

      worked_candles = [copied_candle] ++ worked_candles

      copy_last_price_loop(copied_candle, trades_tail, timeframe, worked_candles)
    else
      [last_candle] ++ worked_candles
    end
  end

  defp get_empty_candle(last_price, stime, etime) do
    %Candle{
      open: last_price,
      high: last_price,
      low: last_price,
      close: last_price,
      volume: 0,
      trades: 0,
      stime: stime,
      etime: etime,
      processed: true
    }
  end

  # Creates new candle.
  defp create_candle(trade, timeframe) do
    trade_data_formatted = format_trade_data(trade)

    %Candle{
      open: trade_data_formatted[:price],
      high: trade_data_formatted[:price],
      low: trade_data_formatted[:price],
      close: trade_data_formatted[:price],
      volume: trade_data_formatted[:volume],
      trades: 1,
      stime: trade_data_formatted[:time],
      etime: get_time_added(timeframe, trade_data_formatted[:time], [format: :stamp]),
      processed: true
    }
  end

  # Returns updated candle.
  defp update_candle(candle, trade) do
    trade_data_formatted = format_trade_data(trade)

    %{
      candle
      | close: trade_data_formatted[:price],
        high: max(trade_data_formatted[:price], candle.high),
        low: min(trade_data_formatted[:price], candle.low),
        volume: trade_data_formatted[:volume] + candle.volume,
        trades: 1 + candle.trades,
        processed: true
    }
  end

  # Formats the trade data.
  defp format_trade_data(trade) do
    trade = Keyword.put(trade, :time, format_to_float(trade[:time]) |> round())
    trade = Keyword.put(trade, :price, format_to_float(trade[:price]))
    trade = Keyword.put(trade, :volume, format_to_float(trade[:volume]))

    trade
  end

  defp format_to_float(value) when is_binary(value) do
    {float, _} = value |> String.replace(",", ".") |> String.trim() |> Float.parse()
    float
  end
  defp format_to_float(value) when is_number(value) or is_integer(value), do: value / 1
  defp format_to_float(value) when is_float(value), do: value


  # Returns true if trade time is bigger then last candles etime.
  defp timeframe_has_candle?(last_candle, trade) do
    if (last_candle.etime !== 0) do
      first_date_greater?(last_candle.etime, trade[:time])
    else
      false
    end
  end

  defp first_date_greater?(first_date, second_date) do
    {:ok, first_date} = first_date |> format_to_float() |> round() |> DateTime.from_unix()
    {:ok, second_date} = second_date |> format_to_float() |> round() |> DateTime.from_unix()

    case DateTime.compare(first_date, second_date) do
      :gt -> true
      :lt -> false
      :eq -> false
    end
  end

  # Formats and returns etime for candles.
  defp get_time_added(timeframe, timestamp, opts \\ []) do

    {:ok, time_struct} = DateTime.from_unix(timestamp)

    candle_etime = %DateTime{
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

    etime =
      case timeframe do
        :minute ->
          end_minutes = DateTime.add(time_struct, 60, :second)

          %{
            candle_etime
            | day: end_minutes.day,
              hour: end_minutes.hour,
              minute: end_minutes.minute,
              second: 0
          }

        :hour ->
          end_hour = DateTime.add(time_struct, 3600, :second)
          %{candle_etime | day: end_hour.day, hour: end_hour.hour, minute: 0, second: 0}

        :day ->
          end_day = DateTime.add(time_struct, 86_400, :second)
          %{candle_etime | day: end_day.day, hour: 0, minute: 0, second: 0}
      end

    case opts[:format] do
      :stamp -> DateTime.to_unix(etime)
      :struct -> etime
      nil -> etime
    end
  end
end
