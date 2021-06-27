defmodule OHLCStaticHourlyTest do
  use ExUnit.Case

  import OHLC

  doctest OHLC

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

    assert length(data[:candles]) === 2 and
             first_candle[:type] === :bearish and
             first_candle[:open] === 125.54 and
             first_candle[:high] === 129.32 and
             first_candle[:low] === 19.3 and
             first_candle[:close] === 119.4 and
             first_candle[:volume] === 41.142 and
             first_candle[:stime] === 1_616_436_000 and
             first_candle[:etime] === 1_616_439_599 and
             first_candle[:trades] === 9 and
             last_candle[:type] === :bullish and
             last_candle[:open] === 12.0 and
             last_candle[:high] === 2222.0 and
             last_candle[:low] === 11.0 and
             last_candle[:close] === 98.4 and
             last_candle[:volume] === 127.73 and
             last_candle[:stime] === 1_616_439_600 and
             last_candle[:etime] === 1_616_443_199 and
             last_candle[:trades] === 9
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
