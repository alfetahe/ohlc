defmodule OHLCStaticWeeklyTest do
  use ExUnit.Case

  import OHLC
  import OHLCHelper

  doctest OHLC

  test "Single weekly candle" do
    trades = single_weekly_candle_1()

    {:ok, data} = create_candles(trades, :week, [:skip_no_trades])

    assert(
      length(data[:candles]) === 1 and
        Enum.at(data[:candles], 0)[:open] === Enum.at(trades, 0)[:price] and
        Enum.at(data[:candles], 0)[:close] === Enum.at(trades, -1)[:price] and
        Enum.at(data[:candles], 0)[:volume] === trades_total_volume(trades)
    )
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
end
