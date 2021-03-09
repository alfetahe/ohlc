defmodule Candloo do
  @moduledoc """
  Documentation for Candloo.
  """

  alias Candloo.Candle

  @no_trade_skip_candle :skip
  @no_trade_copy_last_close :copy_last_close

  @doc """
  Creates OHLC candles from trades.
  """
  def create_candles(
        [[{:price, _}, {:volume, _}, {:time, _}, {:side, _}] | _] = trades,
        timeframe,
        opts \\ []
      ) do

    no_trade_options = [@no_trade_skip_candle, @no_trade_copy_last_close]

    no_trade_option = if (Enum.member?(no_trade_options, opts[:no_trades])) do
      opts[:no_trades]
    else
      # By default were coping the last candles close price if no trades in interval.
      @no_trade_copy_last_close
    end

    loop_trades(trades, [%Candle{}], timeframe, no_trade_option)
  end

  # Loops thru trades and creates or updates candles.
  defp loop_trades(
         [trades_head | trades_tail],
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
            @no_trade_copy_last_close ->
              copy_last_price_loop(candles_head, trades_head, trades_tail, timeframe)

              # @TODO

            @no_trade_skip_candle ->
              candle = create_candle(trades_head, timeframe)
              [candle] ++ candles
          end
      end

    loop_trades(trades_tail, candles, timeframe, no_trade_option)
  end

  # Returns all candles.
  defp loop_trades(trades, candles, _timeframe, _no_trade_option) when length(trades) == 0, do: candles

  defp copy_last_price_loop(last_candle, trades_head, trades_tail, timeframe) do
    # @TODO
    # Kui lisada eelmise candle etime-le timeframe juurde ja kui praeguse trade-i stime on suurem siis tuleks
    # Luua copyitud candle


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
      etime: get_etime(timeframe, trade_data_formatted[:time]),
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
    trade_data_formatted = format_trade_data(trade)

    {:ok, trade_time_struct} = trade_data_formatted[:time] |> DateTime.from_unix()

    {:ok, last_candle_etime} = last_candle.etime |> DateTime.from_unix()

    case DateTime.compare(last_candle_etime, trade_time_struct) do
      :gt -> true
      :lt -> false
      :eq -> false
    end
  end

  # Formats and returns etime for candles.
  defp get_etime(timeframe, trade_time) do
    {:ok, trade_time_struct} = trade_time |> DateTime.from_unix()

    candle_etime = %DateTime{
      year: trade_time_struct.year,
      month: trade_time_struct.month,
      day: 0,
      hour: 0,
      minute: 0,
      second: 0,
      time_zone: trade_time_struct.time_zone,
      zone_abbr: trade_time_struct.zone_abbr,
      utc_offset: trade_time_struct.utc_offset,
      std_offset: trade_time_struct.std_offset
    }

    etime =
      case timeframe do
        :minute ->
          end_minutes = DateTime.add(trade_time_struct, 60, :second)

          %{
            candle_etime
            | day: end_minutes.day,
              hour: end_minutes.hour,
              minute: end_minutes.minute,
              second: 0
          }

        :hour ->
          end_hour = DateTime.add(trade_time_struct, 3600, :second)
          %{candle_etime | day: end_hour.day, hour: end_hour.hour, minute: 0, second: 0}

        :day ->
          end_day = DateTime.add(trade_time_struct, 86_400, :second)
          %{candle_etime | day: end_day.day, hour: 0, minute: 0, second: 0}
      end

    DateTime.to_unix(etime)
  end
end
