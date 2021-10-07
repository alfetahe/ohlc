defmodule OHLCStaticHourlyTest do
  use ExUnit.Case

  import OHLC

  doctest OHLC

  test "Candle merging" do
    {:ok, hour_candles} = create_candles(single_hourly_candle_1(), :day)
    {:ok, minute_candles} = create_candles(single_hourly_candle_2(), :hour)

    {:ok, merged_candle} =
      merge_child(
        hour_candles[:candles]
        |> Enum.at(0),
        minute_candles[:candles] |> Enum.at(0)
      )

    assert merged_candle === %{
             close: 98.4,
             etime: 1_616_457_599,
             high: 2222.0,
             low: 11.0,
             open: 125.54,
             processed: true,
             stime: 1_616_371_200,
             trades: 18,
             type: :bearish,
             volume: 168.872
           }
  end

  test "Candle timeframe converting" do
    trades = single_hourly_candle_1() ++ single_hourly_candle_2()

    {:ok, data} = create_candles(trades, :minute)
    {:ok, converted_timeframe} = convert_timeframe(data[:candles], :hour)

    assert(length(converted_timeframe) == 2)
  end

  test "Test 2 hourly candles" do
    trades = single_hourly_candle_1() ++ single_hourly_candle_2()
    {:ok, data} = create_candles(trades, :hour, forward_fill: true)

    first_candle = Enum.at(data[:candles], 0)
    last_candle = Enum.at(data[:candles], 1)

    assert length(data[:candles]) === 2
    assert first_candle[:type] === :bearish
    assert first_candle[:open] === 125.54
    assert first_candle[:high] === 129.32
    assert first_candle[:low] === 19.3
    assert first_candle[:close] === 119.4
    assert first_candle[:volume] === 41.142
    assert first_candle[:stime] === 1_616_436_000
    assert first_candle[:etime] === 1_616_439_599
    assert first_candle[:trades] === 9
    assert last_candle[:type] === :bullish
    assert last_candle[:open] === 12.0
    assert last_candle[:high] === 2222.0
    assert last_candle[:low] === 11.0
    assert last_candle[:close] === 98.4
    assert last_candle[:volume] === 127.73
    assert last_candle[:stime] === 1_616_439_600
    assert last_candle[:etime] === 1_616_443_199
    assert last_candle[:trades] === 9
  end

  defp single_hourly_candle_1 do
    [
      [price: 125.54, volume: 0.1, time: 1_616_436_299],
      [price: 125.32, volume: 1.4, time: 1_616_436_734],
      [price: 125.12, volume: 1.9, time: 1_616_437_334],
      [price: 126.877, volume: 15, time: 1_616_437_394],
      [price: 19.3, volume: 19.43, time: 1_616_438_474],
      [price: 119, volume: 0.002, time: 1_616_439_119],
      [price: 119.654, volume: 0.89, time: 1_616_439_120],
      [price: 129.32, volume: 1.42, time: 1_616_439_302],
      [price: 119.4, volume: 1, time: 1_616_439_599]
    ]
  end

  defp single_hourly_candle_2 do
    [
      [price: 12, volume: 22, time: 1_616_439_602],
      [price: 12.56, volume: 18.3, time: 1_616_440_572],
      [price: 18.9, volume: 12, time: 1_616_440_692],
      [price: 11, volume: 43, time: 1_616_440_759],
      [price: 199.3, volume: 8.93, time: 1_616_441_583],
      [price: 2222, volume: 8, time: 1_616_441_940],
      [price: 1234, volume: 8, time: 1_616_441_952],
      [price: 44, volume: 7, time: 1_616_442_512],
      [price: 98.4, volume: 0.5, time: 1_616_442_679]
    ]
  end
end
