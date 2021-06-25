defmodule OHLCStaticDailyTest do
  use ExUnit.Case

  import OHLC
  import OHLCHelper

  doctest OHLC

  test "Single daily candles" do
    trades = single_daily_candle_1()

    {:ok, data} = create_candles(trades, :day)

    assert(
      length(data[:candles]) === 1 and
        Enum.at(data[:candles], 0)[:open] === Enum.at(trades, 0)[:price] and
        Enum.at(data[:candles], 0)[:close] === Enum.at(trades, -1)[:price] and
        Enum.at(data[:candles], 0)[:volume] === trades_total_volume(trades)
    )
  end

  defp single_daily_candle_1 do
    [
      [price: 125.54, volume: 0.1, time: 1_616_633_999],
      [price: 125.32, volume: 1.4, time: 1_616_641_905],
      [price: 125.12, volume: 1.9, time: 1_616_674_974],
      [price: 126.877, volume: 15, time: 1_616_702_514],
      [price: 19.3, volume: 19.43, time: 1_616_709_599]
    ]
  end
end
