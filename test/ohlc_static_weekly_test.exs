defmodule OHLCStaticWeeklyTest do
  use ExUnit.Case

  import OHLC
  import OHLCHelper

  doctest OHLC

  test "Test single weekly candle" do
    trades = single_weekly_candle_1()

    {:ok, data} = create_candles(trades, :week)

    assert(
      length(data[:candles]) === 1 and
        Enum.at(data[:candles], 0)[:open] === Enum.at(trades, 0)[:price] and
        Enum.at(data[:candles], 0)[:close] === Enum.at(trades, -1)[:price] and
        Enum.at(data[:candles], 0)[:volume] === trades_total_volume(trades)
    )
  end

  test "Test two weekly candles" do
    trades = single_weekly_candle_1() ++ single_weekly_candle_2()

    {:ok, data} = create_candles(trades, :week)

    first_candle = Enum.at(data[:candles], 0)
    last_candle = Enum.at(data[:candles], 1)

    assert length(data[:candles]) === 2 and
             first_candle[:type] === :bearish and
             first_candle[:open] === 125.54 and
             first_candle[:high] === 126.877 and
             first_candle[:low] === 19.3 and
             first_candle[:close] === 19.3 and
             first_candle[:volume] === 37.83 and
             first_candle[:stime] === 1_616_889_600 and
             first_candle[:etime] === 1_617_580_799 and
             first_candle[:trades] === 5 and
             last_candle[:type] === :bullish and
             last_candle[:open] === 1.0 and
             last_candle[:high] === 4.0 and
             last_candle[:low] === 1.0 and
             last_candle[:close] === 4.0 and
             last_candle[:volume] === 10.0 and
             last_candle[:stime] === 1_617_494_400 and
             last_candle[:etime] === 1_618_185_599 and
             last_candle[:trades] === 4
  end

  defp single_weekly_candle_1 do
    [
      [price: 125.54, volume: 0.1, time: 1_617_010_382],
      [price: 125.32, volume: 1.4, time: 1_617_096_782],
      [price: 125.12, volume: 1.9, time: 1_617_183_182],
      [price: 126.877, volume: 15, time: 1_617_269_582],
      [price: 19.3, volume: 19.43, time: 1_617_355_982]
    ]
  end

  defp single_weekly_candle_2 do
    [
      [price: 1, volume: 1, time: 1_617_660_059],
      [price: 2, volume: 2, time: 1_617_674_519],
      [price: 3, volume: 3, time: 1_617_847_319],
      [price: 4, volume: 4, time: 1_618_171_319]
    ]
  end
end
