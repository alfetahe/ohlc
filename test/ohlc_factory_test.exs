defmodule OHLCFactoryTest do
  use ExUnit.Case

  import OHLCFactory

  doctest OHLCFactory

  test "gen_trades/1" do
    trades = gen_trades()

    assert is_list(trades)

    assert Enum.all?(trades, fn trade ->
             Keyword.has_key?(trade, :price) &&
               Keyword.has_key?(trade, :volume) &&
               Keyword.has_key?(trade, :time)
           end)
  end

  test "gen_empty_candle/1 default" do
    empty_candle = %{
      close: 0.0,
      etime: 0,
      high: 0.0,
      low: 0.0,
      open: 0.0,
      processed: false,
      stime: 0,
      trades: 0,
      type: nil,
      volume: 0.0
    }

    assert gen_empty_candle() === empty_candle
  end

  test "gen_empty_candle/1 minute" do
    timeframe = :minute
    empty_candle = gen_empty_candle_test(timeframe)

    assert gen_empty_candle(timeframe) === empty_candle
  end

  test "gen_empty_candle/1 hour" do
    timeframe = :hour
    empty_candle = gen_empty_candle_test(timeframe)

    assert gen_empty_candle(timeframe) === empty_candle
  end

  test "gen_empty_candle/1 day" do
    timeframe = :day
    empty_candle = gen_empty_candle_test(timeframe)

    assert gen_empty_candle(timeframe) === empty_candle
  end

  test "gen_empty_candle/1 week" do
    timeframe = :week

    empty_candle = gen_empty_candle_test(timeframe)

    assert gen_empty_candle(timeframe) === empty_candle
  end

  test "gen_candles/3 amount" do
    amount = 11
    candles = gen_candles(:minute, amount)

    assert length(candles) === amount
  end

  test "gen_candles/3 prices increase minute" do
    timeframe = :minute
    amount = 74
    base_price = 123.55
    price_change_percentage = 3.5
    price_direction = :increase

    candles =
      gen_candles(timeframe, amount,
        base_price: base_price,
        price_change_percentage: price_change_percentage,
        price_direction: price_direction
      )
      |> Enum.reverse()

    assert validate_candles(
             candles,
             timeframe,
             price_direction,
             base_price,
             price_change_percentage
           )
  end

  test "gen_candles/3 prices decrease minute" do
    timeframe = :minute
    amount = 124
    base_price = 3672.256
    price_change_percentage = 2.22
    price_direction = :decrease

    candles =
      gen_candles(timeframe, amount,
        base_price: base_price,
        price_change_percentage: price_change_percentage,
        price_direction: price_direction
      )
      |> Enum.reverse()

    assert validate_candles(
             candles,
             timeframe,
             price_direction,
             base_price,
             price_change_percentage
           )
  end

  test "gen_candles/3 prices increase hour" do
    timeframe = :hour
    amount = 2
    base_price = 123.55
    price_change_percentage = 3.5
    price_direction = :increase

    candles =
      gen_candles(timeframe, amount,
        base_price: base_price,
        price_change_percentage: price_change_percentage,
        price_direction: price_direction
      )
      |> Enum.reverse()

    assert validate_candles(
             candles,
             timeframe,
             price_direction,
             base_price,
             price_change_percentage
           )
  end

  test "gen_candles/3 prices decrease hour" do
    timeframe = :hour
    amount = 20
    base_price = 1023
    price_change_percentage = 1
    price_direction = :decrease

    candles =
      gen_candles(timeframe, amount,
        base_price: base_price,
        price_change_percentage: price_change_percentage,
        price_direction: price_direction
      )
      |> Enum.reverse()

    assert validate_candles(
             candles,
             timeframe,
             price_direction,
             base_price,
             price_change_percentage
           )
  end

  test "gen_candles/3 prices decrease day" do
    timeframe = :day
    amount = 21
    base_price = 0.55
    price_change_percentage = 10.3
    price_direction = :decrease

    candles =
      gen_candles(timeframe, amount,
        base_price: base_price,
        price_change_percentage: price_change_percentage,
        price_direction: price_direction
      )
      |> Enum.reverse()

    assert validate_candles(
             candles,
             timeframe,
             price_direction,
             base_price,
             price_change_percentage
           )
  end

  test "gen_candles/3 prices increase day" do
    timeframe = :day
    amount = 121
    base_price = 0.5678
    price_change_percentage = 30.3
    price_direction = :increase

    candles =
      gen_candles(timeframe, amount,
        base_price: base_price,
        price_change_percentage: price_change_percentage,
        price_direction: price_direction
      )
      |> Enum.reverse()

    assert validate_candles(
             candles,
             timeframe,
             price_direction,
             base_price,
             price_change_percentage
           )
  end

  test "gen_candles/3 prices decrease week" do
    timeframe = :week
    amount = 4
    base_price = 0.12
    price_change_percentage = 15.3
    price_direction = :decrease

    candles =
      gen_candles(timeframe, amount,
        base_price: base_price,
        price_change_percentage: price_change_percentage,
        price_direction: price_direction
      )
      |> Enum.reverse()

    assert validate_candles(
             candles,
             timeframe,
             price_direction,
             base_price,
             price_change_percentage
           )
  end

  test "gen_candles/3 prices increase week" do
    timeframe = :week
    amount = 16
    base_price = 100
    price_change_percentage = 0.3
    price_direction = :increase

    candles =
      gen_candles(timeframe, amount,
        base_price: base_price,
        price_change_percentage: price_change_percentage,
        price_direction: price_direction
      )
      |> Enum.reverse()

    assert validate_candles(
             candles,
             timeframe,
             price_direction,
             base_price,
             price_change_percentage
           )
  end

  test "gen_candles/3 minute rand" do
    timeframe = :minute
    amount = 19
    candles = gen_candles(timeframe, amount) |> Enum.reverse()

    assert validate_candles(candles, timeframe)
  end

  test "gen_candles/3 hour rand" do
    timeframe = :hour
    amount = 11
    candles = gen_candles(timeframe, amount) |> Enum.reverse()

    assert validate_candles(candles, timeframe)
  end

  test "gen_candles/3 day rand" do
    timeframe = :day
    amount = 9
    candles = gen_candles(timeframe, amount) |> Enum.reverse()

    assert validate_candles(candles, timeframe)
  end

  test "gen_candles/3 week rand" do
    timeframe = :week
    amount = 4
    candles = gen_candles(timeframe, amount) |> Enum.reverse()

    assert validate_candles(candles, timeframe)
  end

  defp validate_candles(
         candles,
         timeframe,
         price_direction \\ :rand,
         base_price \\ 9,
         price_change_percentage \\ 1
       ) do
    change_seconds = OHLCHelper.get_timeframes()[timeframe]

    curr_stamp = DateTime.utc_now() |> DateTime.to_unix()
    base_stime = OHLCHelper.get_time_rounded(curr_stamp, timeframe, type: :down)

    Enum.map_reduce(candles, 1, fn candle, counter ->
      updated_stime = base_stime - counter * change_seconds
      etime = OHLCHelper.get_time_rounded(updated_stime, timeframe)

      price_validations =
        case price_direction do
          :rand ->
            true

          :increase ->
            candle[:open] ===
              base_price / 100 * (price_change_percentage * (counter + 1.1)) + base_price

            candle[:high] ===
              base_price / 100 * (price_change_percentage * (counter + 1.3)) + base_price

            candle[:low] ===
              base_price / 100 * (price_change_percentage * (counter + 1)) + base_price

            candle[:close] ===
              base_price / 100 * (price_change_percentage * (counter + 1.2)) + base_price

            candle[:type] === :bullish

          :decrease ->
            candle[:open] ===
              base_price * (1.0 - price_change_percentage * (counter + 1.1) / 100)

            candle[:high] ===
              base_price * (1.0 - price_change_percentage * (counter + 1.3) / 100)

            candle[:low] ===
              base_price * (1.0 - price_change_percentage * (counter + 1) / 100)

            candle[:close] ===
              base_price * (1.0 - price_change_percentage * (counter + 1.2) / 100)

            candle[:type] === :bearish
        end

      {
        updated_stime === candle[:stime] &&
          etime === candle[:etime] &&
          price_validations,
        counter + 1
      }
    end)
    |> elem(0)
    |> Enum.all?(& &1)
  end

  defp gen_empty_candle_test(timeframe) do
    curr_timestamp =
      DateTime.utc_now()
      |> DateTime.to_unix()

    stime = OHLCHelper.get_time_rounded(curr_timestamp, timeframe, type: :down)
    etime = OHLCHelper.get_time_rounded(curr_timestamp, timeframe, type: :up)

    %{
      close: 0.0,
      etime: etime,
      high: 0.0,
      low: 0.0,
      open: 0.0,
      processed: false,
      stime: stime,
      trades: 0,
      type: nil,
      volume: 0.0
    }
  end
end
