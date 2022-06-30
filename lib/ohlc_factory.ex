defmodule OHLCFactory do
  @moduledoc """
  This module provides functionality to generate random or
  defined OHLC candles or trades which can be used for testing,
  demoing etc.
  """

  # 2021-22-03 00:00:00 UTC +0
  @base_timestamp 1_616_371_200

  @base_volume 9
  @base_trades 9
  @base_price 9

  @doc """
  Generates trades from provided arguments.

  Options:
  - `timeframe` - Timeframe used for rounding the timestamp.
  Available values are: `:minute`, `:hour`, `:day`, `:week`
  - `min_price` - The minimum price on the generated trades
  - `max_price` - The maximum price on the generated trades
  - `volume` - The volume each trade has
  - `timeframe_multiplier` - If you'd like to generate less trades per candle then you can increase the size of
  the timeframe_divider parameter(1-100) otherwise leave empty.
  - `timeframe_divider` - Is used for generating multiple candles of the same timeframe.
  """
  @spec gen_trades(keyword() | nil) :: list()
  def gen_trades(opts \\ []) do
    timeframe = Keyword.get(opts, :timeframe, :minute)
    min_price = Keyword.get(opts, :min_price, 10)
    max_price = Keyword.get(opts, :max_price, 20)
    volume = Keyword.get(opts, :volume, 10)
    timeframe_multiplier = Keyword.get(opts, :timeframe_multiplier, 1)
    timeframe_divider = Keyword.get(opts, :timeframe_divider, 1)

    timeframe_secs = OHLCHelper.get_timeframes()[timeframe]

    price_range = max_price - min_price

    if is_float(price_range), do: Float.round(price_range, 4), else: price_range

    timestamp_multipled = @base_timestamp + timeframe_secs * timeframe_multiplier

    items_to_loop = ((timeframe_secs - 1) / timeframe_divider) |> trunc()

    Enum.map(1..items_to_loop, fn numb ->
      numb_multiplied = numb * timeframe_divider

      price =
        cond do
          numb === 1 ->
            max_price

          numb === items_to_loop ->
            min_price

          true ->
            (price_range / numb_multiplied + min_price) |> Float.round(4)
        end

      price = (is_float(price) && Float.round(price, 4)) || price
      volume = (is_float(volume) && Float.round(volume, 4)) || volume

      [
        price: price,
        volume: volume,
        time: timestamp_multipled + numb_multiplied
      ]
    end)
  end

  @doc """
  Generates empty OHLC candle.

  If provided with timeframe stime and etime will be
  generated based on current time.
  """
  @spec gen_empty_candle(OHLC.timeframe() | nil) :: OHLC.candle()
  def gen_empty_candle(timeframe \\ nil) do
    {stime, etime} =
      case timeframe do
        nil ->
          {0, 0}

        _ ->
          curr_timestamp =
            DateTime.utc_now()
            |> DateTime.to_unix()

          {
            OHLCHelper.get_time_rounded(curr_timestamp, timeframe, type: :down),
            OHLCHelper.get_time_rounded(curr_timestamp, timeframe, type: :up)
          }
      end

    %{
      :open => 0.0,
      :high => 0.0,
      :low => 0.0,
      :close => 0.0,
      :volume => 0.0,
      :trades => 0,
      :stime => stime,
      :etime => etime,
      :type => nil,
      :processed => false
    }
  end

  @doc """
  Generates candles based on parameters provided.

  Parameters:
  - timeframe - See available timeframes `OHLCHelper.get_timeframes`.
  - amount - Amount of candles to generate. Must be bigger than 0.

  Available options:
  - `:base_price` - Base price to use when generating candles. Defaults to 9.
  - `:price_direction` - Generated candles can increase or decrease in price.
  `:increase`, `:decrease` or `:rand` which is used by default.
  - `:price_change_percentage` - With each new candle we dynamically update the price
  for each new candle. This price can be higher than the previous candle or lesser.
  With this option you can choose the percentage change for each new candle.
  Defaults to 1% change with each new candle.
  """
  @spec gen_candles(OHLC.timeframe(), number(), keyword() | nil) :: list()
  def gen_candles(timeframe, amount, opts \\ []) do
    curr_stamp = DateTime.utc_now() |> DateTime.to_unix()
    base_stime = OHLCHelper.get_time_rounded(curr_stamp, timeframe, type: :down)
    change_seconds = OHLCHelper.get_timeframes()[timeframe]
    base_price = Keyword.get(opts, :base_price, @base_price)
    price_change_percentage = Keyword.get(opts, :price_change_percentage, 1)
    price_direction = Keyword.get(opts, :price_direction, :rand)

    Enum.map(1..amount, fn counter ->
      updated_stime = base_stime - counter * change_seconds

      price_direction =
        if price_direction === :rand do
          Enum.random([:increase, :decrease])
        else
          price_direction
        end

      {open, high, low, close, type} =
        gen_ohlc_data(price_direction, base_price, price_change_percentage, counter)

      etime = OHLCHelper.get_time_rounded(updated_stime, timeframe)

      gen_empty_candle(timeframe)
      |> Map.put(:volume, @base_volume)
      |> Map.put(:trades, @base_trades)
      |> Map.put(:stime, updated_stime)
      |> Map.put(:etime, etime)
      |> Map.put(:open, open)
      |> Map.put(:close, close)
      |> Map.put(:high, high)
      |> Map.put(:low, low)
      |> Map.put(:type, type)
    end)
    |> Enum.reverse()
  end

  defp percentage_change(initial_val, percentage, type) do
    case type do
      :increase -> initial_val / 100 * percentage + initial_val
      :decrease -> initial_val * (1.0 - percentage / 100)
    end
  end

  defp gen_ohlc_data(price_direction, base_price, price_change_percentage, counter) do
    case price_direction do
      :increase ->
        {
          percentage_change(base_price, price_change_percentage * (counter + 1.1), :increase),
          percentage_change(base_price, price_change_percentage * (counter + 1.3), :increase),
          percentage_change(base_price, price_change_percentage * (counter + 1), :increase),
          percentage_change(base_price, price_change_percentage * (counter + 1.2), :increase),
          :bullish
        }

      :decrease ->
        {
          percentage_change(base_price, price_change_percentage * (counter + 1.1), :decrease),
          percentage_change(base_price, price_change_percentage * (counter + 1), :decrease),
          percentage_change(base_price, price_change_percentage * (counter + 1.3), :decrease),
          percentage_change(base_price, price_change_percentage * (counter + 1.2), :decrease),
          :bearish
        }
    end
  end
end
