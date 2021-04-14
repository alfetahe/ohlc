defmodule Candloo do
  @moduledoc """
  Documentation for Candloo.
  """

  @no_trades_skip_candles :skip_no_trades
  @no_trades_copy_last_close :copy_last_close
  @timeframes [{:minute, 60}, {:hour, 3600}, {:day, 86_400}, {:week, 604_800}]

  @doc """
  Creates OHLC candles from trades.
  """
  def create_candles(
        [[{:price, _}, {:volume, _}, {:time, _}, {:side, _}] | _] = trades,
        timeframe,
        opts \\ []
      ) do
    candles = [generate_empty_candle()]

    construct_candles(candles, trades, timeframe, opts)
  end

  def append_or_create_candles(
        %{} = candle,
        [[{:price, _}, {:volume, _}, {:time, _}, {:side, _}] | _] = trades,
        timeframe,
        opts \\ []
      ) do
    construct_candles([candle], trades, timeframe, opts)
  end

  defp generate_empty_candle() do
    %{
      etime: 0,
      stime: 0,
      open: 0,
      high: 0,
      low: nil,
      close: 0,
      volume: 0,
      trades: 0,
      processed: false
    }
  end

  defp construct_candles(candles, trades, timeframe, opts) do
    no_trade_option = set_trade_option(opts)

    case validate_data(trades, timeframe) do
      {:error, msg} ->
        {:error, msg}

      {:ok, _} ->
        data = %{
          "pair" => opts[:pair],
          "timeframe" => timeframe,
          "candles" => loop_trades(trades, candles, timeframe, no_trade_option)
        }

        {:ok, data}
    end
  end

  defp set_trade_option(opts) do
    if Enum.member?(opts, @no_trades_skip_candles) do
      @no_trades_skip_candles
    else
      # By default were coping the last candles close price if no trades in interval.
      @no_trades_copy_last_close
    end
  end

  defp validate_data(trades, timeframe) do
    case validate_timeframe(timeframe) do
      {:error, timeframe_error_msg} ->
        {:error, timeframe_error_msg}

      {:ok, _} ->
        trades_validated = validate_trades(trades)

        case trades_validated do
          {:error, trades_error_msg} -> {:error, trades_error_msg}
          {:ok, _} -> {:ok, "Data has been validated."}
        end
    end
  end

  defp validate_timeframe(timeframe) do
    case @timeframes[timeframe] do
      nil -> {:error, "Timeframe is not defined in the modules: #{timeframe}"}
      _ -> {:ok, "Timeframe validated."}
    end
  end

  defp validate_trades(trades, prev_etime \\ nil)

  defp validate_trades([trades_head | trades_body], prev_etime) do
    trade_fields = [:price, :volume, :time, :side]

    keys_validated = Enum.all?(trade_fields, &trades_head[&1])

    case keys_validated do
      true ->
        trade_data_validated = validate_trade_data(trades_head, prev_etime)

        case trade_data_validated do
          {:ok, _} -> validate_trades(trades_body, trades_head[:time])
          {:error, msg} -> {:error, msg}
        end

      false ->
        {:error, "Trades list does not contain all necessary keys"}
    end
  end

  defp validate_trades([], _prev_etime) do
    {:ok, "Trade fields have been validated."}
  end

  defp validate_trade_data(trade, prev_etime) do
    price_validation = is_float(format_to_float(trade[:price]))
    time_validation = is_float(format_to_float(trade[:time]))
    volume_validation = is_float(format_to_float(trade[:volume]))
    side_validation = trade[:side] === "s" or trade[:side] === "b" || false

    etime_greater =
      cond do
        prev_etime === nil -> true
        time_validation -> format_to_float(trade[:time]) >= format_to_float(prev_etime) || false
        true -> false
      end

    if price_validation and time_validation and volume_validation and side_validation and
         etime_greater do
      {:ok, "Trade data validated."}
    else
      {:error,
       "Error validating trades data. Data types wrong or not sequenced: #{inspect(trade)}"}
    end
  end

  # Loops thru trades and creates or updates candles.
  defp loop_trades(
         [trades_head | trades_tail] = trades,
         [candles_head | candles_body] = candles,
         timeframe,
         no_trade_option
       ) do
    formatted_trade_data = format_trade_data(trades_head)

    dates_match =
      dates_match_timeframe(candles_head.etime, formatted_trade_data[:time], timeframe)

    [candles, trades_tail] =
      cond do
        # Appends new candle to the candles list without the unprocessed candle.
        !candles_head.processed ->
          candle = create_candle(formatted_trade_data, timeframe)
          [[candle] ++ candles_body, trades_tail]

        # Updates last candle.
        dates_match === :eq ->
          updated_candle = update_candle(candles_head, formatted_trade_data)
          [[updated_candle] ++ candles_body, trades_tail]

        # Creates new candle or candles.
        dates_match === :lt or dates_match === :gt or dates_match === :empty_first_date ->
          case no_trade_option do
            @no_trades_copy_last_close ->
              copy_or_create_loop([candles_head | candles_body], trades, timeframe)

            @no_trades_skip_candles ->
              candle = create_candle(formatted_trade_data, timeframe)
              [[candle] ++ candles, trades_tail]
          end
      end

    loop_trades(trades_tail, candles, timeframe, no_trade_option)
  end

  # Returns all candles.
  defp loop_trades(trades, candles, _timeframe, _no_trade_option) when length(trades) == 0,
    do: candles

  defp copy_or_create_loop(
         [candles_head | _candles_body] = candles,
         [trades_head | trades_tail] = trades,
         timeframe
       ) do
    trade_formatted = format_trade_data(trades_head)
    candles_head_etime_added = get_etime_rounded(candles_head.etime, timeframe, type: :add)

    date_check =
      dates_match_timeframe(
        trade_formatted[:time],
        candles_head_etime_added,
        timeframe
      )

    cond do
      date_check === :eq or date_check === :lt ->
        candle = create_candle(trade_formatted, timeframe)
        [[candle] ++ candles, trades_tail]

      date_check === :gt ->
        copied_candle =
          get_empty_candle(
            candles_head.close,
            candles_head_etime_added,
            candles_head_etime_added
          )

        candles = [copied_candle] ++ candles

        copy_or_create_loop(candles, trades, timeframe)
    end
  end

  defp get_empty_candle(last_price, stime, etime) do
    %{
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
    %{
      open: trade[:price],
      high: trade[:price],
      low: trade[:price],
      close: trade[:price],
      volume: trade[:volume],
      trades: 1,
      stime: trade[:time],
      etime: get_etime_rounded(trade[:time], timeframe),
      processed: true
    }
  end

  # Returns updated candle.
  defp update_candle(candle, trade) do
    %{
      candle
      | close: trade[:price],
        high: max(trade[:price], candle.high) |> Float.round(4),
        low: min(trade[:price], candle.low) |> Float.round(4),
        volume: (trade[:volume] + candle.volume) |> Float.round(4),
        trades: 1 + candle.trades,
        processed: true
    }
  end

  # Formats the trade data.
  defp format_trade_data(trade) do
    trade = Keyword.put(trade, :time, format_to_float(trade[:time]) |> round())
    trade = Keyword.put(trade, :price, format_to_float(trade[:price]) |> Float.round(4))
    trade = Keyword.put(trade, :volume, format_to_float(trade[:volume]) |> Float.round(4))

    trade
  end

  def format_to_float(value) when is_binary(value) do
    {float, _} = value |> String.replace(",", ".") |> String.trim() |> Float.parse()
    float
  end

  def format_to_float(value) when is_number(value) or is_integer(value), do: value / 1
  def format_to_float(value) when is_float(value), do: value
  def format_to_float(value), do: {:error, "Data not formattable to float: #{value}"}

  defp dates_match_timeframe(first_date, second_date, timeframe) do
    if first_date !== 0 do
      first_date = get_etime_rounded(first_date, timeframe, format: :struct)
      second_date = get_etime_rounded(second_date, timeframe, format: :struct)

      DateTime.compare(first_date, second_date)
    else
      :empty_first_date
    end
  end

  # Formats and returns etime for candles.
  def get_etime_rounded(timestamp, timeframe, opts \\ []) do
    timestamp = timestamp |> format_to_float() |> round()

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
        :minute -> etime_minute_worker(time_struct, candle_etime, opts)
        :hour -> etime_hour_worker(time_struct, candle_etime, opts)
        :day -> etime_day_worker(time_struct, candle_etime, opts)
        :week -> etime_week_worker(time_struct, candle_etime, opts)
      end

    case opts[:format] do
      :stamp -> DateTime.to_unix(etime)
      :struct -> etime
      nil -> DateTime.to_unix(etime)
    end
  end

  defp etime_minute_worker(time_struct, unfinished_time_struct, opts) do
    worked_time_struct =
      if time_struct.second === 0 do
        time_struct
      else
        DateTime.add(time_struct, 60, :second)
      end

    worked_time_struct =
      case opts[:type] do
        :add -> DateTime.add(worked_time_struct, 60, :second)
        :substract -> DateTime.add(worked_time_struct, -60, :second)
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

  defp etime_hour_worker(time_struct, unfinished_time_struct, opts) do
    worked_time_struct =
      if time_struct.second === 0 and time_struct.minute === 0 do
        time_struct
      else
        DateTime.add(time_struct, 3600, :second)
      end

    worked_time_struct =
      case opts[:type] do
        :add -> DateTime.add(worked_time_struct, 3600, :second)
        :substract -> DateTime.add(worked_time_struct, -3600, :second)
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

  defp etime_day_worker(time_struct, unfinished_time_struct, opts) do
    worked_time_struct =
      if time_struct.second === 0 and time_struct.minute === 0 and time_struct.hour === 0 do
        time_struct
      else
        DateTime.add(time_struct, 86_400, :second)
      end

    worked_time_struct =
      case opts[:type] do
        :add -> DateTime.add(worked_time_struct, 86_400, :second)
        :substract -> DateTime.add(worked_time_struct, -86_400, :second)
        nil -> worked_time_struct
      end

    %{unfinished_time_struct | day: worked_time_struct.day, hour: 0, minute: 0, second: 0}
  end

  defp etime_week_worker(time_struct, unfinished_time_struct, opts) do
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
        :add -> DateTime.add(worked_time_struct, 604_800, :second)
        :substract -> DateTime.add(worked_time_struct, -604_800, :second)
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
