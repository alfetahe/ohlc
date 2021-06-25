defmodule OHLC do
  @moduledoc """
  Library for generating OHLC candles from trades.


  """

  import OHLCHelper

  @typedoc """
  Single trade piece. This is the correct format for the trade in the trades list.
  """
  @type trade :: [
          {:price, number()}
          | {:volume, number()}
          | {:time, number()}
        ]

  @typedoc """
  Available timeframes for `create_candles/3`
  """
  @type timeframe :: :minute | :hour | :day | :week

  @typedoc """
  Available options for `create_candles/3`
  - `:forward_fill` - When set true copies the previous candles closing price
  to the next candle if no trades happend to be in between.
  Useful when you don't want to get empty time gap between the generated candles.
  - `:validate_trades` - When set true all trades are being validated before
  generating the candles to avoid errors and misinformation.
  - `:previous_candle` - Trades are appended to the previous candle if possible
  before generating the new candles.
  """
  @type opts :: [
          {:forward_fill, boolean()}
          | {:validate_trades, boolean()}
          | {:previous_candle, map() | nil}
        ]

  @spec create_candles([] | [trade()] | [trade() | list()], timeframe(), opts() | nil) ::
          {:ok, map()} | {:error, binary()}
  def create_candles(trades, timeframe, opts \\ []) do
    candles =
      cond do
        opts[:previous_candle] === %{} or opts[:previous_candle] === nil ->
          [generate_empty_candle()]

        true ->
          [opts[:previous_candle]]
      end

    construct_candles(candles, trades, timeframe, opts)
  end

  defp construct_candles(candles, trades, timeframe, opts) do
    if opts[:validate_trades] do
      case validate_data(candles, trades) do
        {:error, msg} ->
          {:error, msg}

        {:ok, _} ->
          set_return_data(candles, trades, timeframe, opts)
      end
    else
      set_return_data(candles, trades, timeframe, opts)
    end
  end

  defp set_return_data(candles, trades, timeframe, opts) do
    data = %{
      "pair" => opts[:pair],
      "timeframe" => timeframe,
      "candles" => loop_trades(trades, candles, timeframe, opts)
    }

    {:ok, data}
  end

  defp validate_data(candles, trades) do
    case validate_candles(candles) do
      {:error, candles_error_msg} ->
        {:error, candles_error_msg}

      {:ok, _} ->
        trades_validated = validate_trades(trades)

        case trades_validated do
          {:error, trades_error_msg} -> {:error, trades_error_msg}
          {:ok, _} -> {:ok, "Data has been validated."}
        end
    end
  end

  defp validate_candles(candles) do
    data_validated = Enum.all?(candles, fn candle -> is_map(candle) end)

    if data_validated do
      {:ok, "Candles validated."}
    else
      {:error, "Candles must be type of map."}
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
        {:ok, "Trade data validated."}
    end
  end

  # Loops thru trades and creates or updates candles.
  defp loop_trades(
         [trades_head | trades_tail] = trades,
         [candles_head | candles_body] = candles,
         timeframe,
         opts
       ) do
    formatted_trade_data = format_trade_data(trades_head)

    dates_match =
      dates_match_timeframe(candles_head["etime"], formatted_trade_data[:time], timeframe)

    [candles, trades_tail] =
      cond do
        # Appends new candle to the candles list without the unprocessed candle.
        !candles_head["processed"] ->
          candle = create_candle(formatted_trade_data, timeframe)
          [[candle] ++ candles_body, trades_tail]

        # Updates last candle.
        dates_match === :eq ->
          updated_candle = update_candle(candles_head, formatted_trade_data)
          [[updated_candle] ++ candles_body, trades_tail]

        # Creates new candle or candles.
        dates_match === :lt or dates_match === :gt or dates_match === :empty_first_date ->
          case opts[:forward_fill] do
            true ->
              candle = create_candle(formatted_trade_data, timeframe)
              [[candle] ++ candles, trades_tail]

            _ ->
              copy_or_create_loop([candles_head | candles_body], trades, timeframe)
          end
      end

    loop_trades(trades_tail, candles, timeframe, opts)
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
    candles_head_etime_added = get_time_rounded(candles_head["etime"], timeframe, type: :jump)

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
            candles_head["close"],
            candles_head_etime_added,
            candles_head_etime_added
          )

        candles = [copied_candle] ++ candles

        copy_or_create_loop(candles, trades, timeframe)
    end
  end

  defp get_empty_candle(last_price, stime, etime) do
    %{
      "open" => last_price,
      "high" => last_price,
      "low" => last_price,
      "close" => last_price,
      "volume" => 0,
      "trades" => 0,
      "stime" => stime,
      "etime" => etime,
      "processed" => true
    }
  end

  # Creates new candle.
  defp create_candle(trade, timeframe) do
    %{
      "open" => trade[:price],
      "high" => trade[:price],
      "low" => trade[:price],
      "close" => trade[:price],
      "volume" => trade[:volume],
      "trades" => 1,
      "stime" => get_time_rounded(trade[:time], timeframe, type: :down),
      "etime" => get_time_rounded(trade[:time], timeframe),
      "processed" => true
    }
  end

  # Returns updated candle.
  defp update_candle(candle, trade) do
    %{
      candle
      | "close" => trade[:price],
        "high" => max(trade[:price], candle["high"]) |> Float.round(4),
        "low" => min(trade[:price], candle["low"]) |> Float.round(4),
        "volume" => (trade[:volume] + candle["volume"]) |> Float.round(4),
        "trades" => 1 + candle["trades"],
        "processed" => true
    }
  end

  # Formats the trade data.
  defp format_trade_data(trade) do
    trade = Keyword.put(trade, :time, format_to_float(trade[:time]) |> round())
    trade = Keyword.put(trade, :price, format_to_float(trade[:price]) |> Float.round(4))
    trade = Keyword.put(trade, :volume, format_to_float(trade[:volume]) |> Float.round(4))

    trade
  end

  defp dates_match_timeframe(first_date, second_date, timeframe) do
    if first_date !== 0 do
      first_date = get_time_rounded(first_date, timeframe, format: :struct)
      second_date = get_time_rounded(second_date, timeframe, format: :struct)

      DateTime.compare(first_date, second_date)
    else
      :empty_first_date
    end
  end

end
