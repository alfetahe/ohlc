defmodule OHLCStaticDailyTest do
  use ExUnit.Case

  import OHLC
  import OHLCHelper

  doctest OHLC

  test "Test single daily candle" do
    trades = single_daily_candle_1()

    {:ok, data} = create_candles(trades, :day)

    assert length(data[:candles]) === 1
    assert Enum.at(data[:candles], 0)[:open] === Enum.at(trades, 0)[:price]
    assert Enum.at(data[:candles], 0)[:close] === Enum.at(trades, -1)[:price]
    assert Enum.at(data[:candles], 0)[:volume] === trades_total_volume(trades)
  end

  test "Test 2 daily candles with forward fill" do
    trades = single_daily_candle_1() ++ single_daily_candle_2()

    {:ok, data} = create_candles(trades, :day, forward_fill: true)

    first_candle = Enum.at(data[:candles], 0)
    copy_candle = Enum.at(data[:candles], 1)
    last_candle = Enum.at(data[:candles], 2)

    assert length(data[:candles]) === 3
    assert first_candle[:type] === :bearish
    assert first_candle[:open] === 125.54
    assert first_candle[:high] === 126.877
    assert first_candle[:low] === 19.3
    assert first_candle[:close] === 19.3
    assert first_candle[:volume] === 37.83
    assert first_candle[:stime] === 1_616_630_400
    assert first_candle[:etime] === 1_616_716_799
    assert first_candle[:trades] === 5
    assert copy_candle[:type] === nil
    assert copy_candle[:open] === 19.3
    assert copy_candle[:high] === 0.0
    assert copy_candle[:low] === 0.0
    assert copy_candle[:close] === 19.3
    assert copy_candle[:volume] === 0.0
    assert copy_candle[:stime] === 1_616_716_799
    assert copy_candle[:etime] === 1_616_716_800
    assert copy_candle[:trades] === 0
    assert last_candle[:type] === :bullish
    assert last_candle[:open] === 0.1
    assert last_candle[:high] === 0.43
    assert last_candle[:low] === 0.1
    assert last_candle[:close] === 0.3
    assert last_candle[:volume] === 18.4
    assert last_candle[:stime] === 1_616_803_200
    assert last_candle[:etime] === 1_616_889_599
    assert last_candle[:trades] === 4
  end

  test "Test 3 daily candles with forward fill false" do
    trades = multiple_daily_candle_1()

    {:ok, data} = create_candles(trades, :day, forward_fill: false)

    first_candle = Enum.at(data[:candles], 0)
    second_candle = Enum.at(data[:candles], 1)
    third_candle = Enum.at(data[:candles], 2)

    assert length(data[:candles]) === 3

    assert first_candle[:type] === :bullish
    assert first_candle[:low] === 0.97
    assert first_candle[:high] === 1.1
    assert first_candle[:open] === 0.98
    assert first_candle[:close] === 1.1
    assert first_candle[:volume] === 690.32

    assert second_candle[:type] === :bearish
    assert second_candle[:low] === 1.1
    assert second_candle[:high] === 1.2
    assert second_candle[:open] === 1.2
    assert second_candle[:close] === 1.1
    assert second_candle[:volume] === 264.2

    assert third_candle[:type] === :bullish
    assert third_candle[:low] === 1.12
    assert third_candle[:high] === 1.456
    assert third_candle[:open] === 1.12
    assert third_candle[:close] === 1.456
    assert third_candle[:volume] === 206.04
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

  defp single_daily_candle_2 do
    [
      [price: 0.1, volume: 0.1, time: 1_616_849_302],
      [price: 0.43, volume: 1.4, time: 1_616_852_902],
      [price: 0.4, volume: 1.9, time: 1_616_868_022],
      [price: 0.3, volume: 15, time: 1_616_882_362]
    ]
  end

  defp multiple_daily_candle_1 do
    [
      [price: 0.98, volume: 150.12, time: 1_681_399_134],
      [price: 0.97, volume: 340.2, time: 1_681_391_934],
      [price: 1.1, volume: 200, time: 1_681_398_752],
      [price: 1.2, volume: 152.2, time: 1_681_438_325],
      [price: 1.1, volume: 112, time: 1_681_438_565],
      [price: 1.12, volume: 50.4, time: 1_681_517_635],
      [price: 1.23, volume: 154.64, time: 1_681_550_161],
      [price: 1.456, volume: 1, time: 1_681_589_461]
    ]
  end
end
