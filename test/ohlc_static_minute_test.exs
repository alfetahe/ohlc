defmodule OHLCStaticMinuteTest do
  use ExUnit.Case

  import OHLC

  doctest OHLC

  test "Single one minute candle test" do
    {:ok, data} = create_candles(single_min_data_2(), :minute)

    candle = Enum.at(data[:candles], 0)

    assert length(data[:candles]) === 1
    assert candle[:type] === :bullish
    assert candle[:open] === 15.0
    assert candle[:high] === 167.5
    assert candle[:low] === 0.3
    assert candle[:close] === 18.11
    assert candle[:volume] === 1380.6
    assert candle[:stime] === 1_616_436_300
    assert candle[:etime] === 1_616_436_359
    assert candle[:trades] === 14
  end

  test "Two one minute candles test" do
    trades = single_min_data_1() ++ single_min_data_2()
    {:ok, data} = create_candles(trades, :minute)

    first_candle = Enum.at(data[:candles], 0)
    last_candle = Enum.at(data[:candles], 1)

    assert length(data[:candles]) === 2
    assert first_candle[:type] === :bullish
    assert first_candle[:open] === 15.0
    assert first_candle[:high] === 17.9
    assert first_candle[:low] === 15.0
    assert first_candle[:close] === 17.9
    assert first_candle[:volume] === 1.4
    assert first_candle[:stime] === 1_616_436_240
    assert first_candle[:etime] === 1_616_436_299
    assert first_candle[:trades] === 3
    assert last_candle[:type] === :bullish
    assert last_candle[:open] === 15.0
    assert last_candle[:high] === 167.5
    assert last_candle[:low] === 0.3
    assert last_candle[:close] === 18.11
    assert last_candle[:volume] === 1380.6
    assert last_candle[:stime] === 1_616_436_300
    assert last_candle[:etime] === 1_616_436_359
    assert last_candle[:trades] === 14
  end

  defp single_min_data_1() do
    [
      [price: 15, volume: 0.2, time: 1_616_436_287],
      [price: 17, volume: 0.6, time: 1_616_436_292],
      [price: 17.9, volume: 0.6, time: 1_616_436_299]
    ]
  end

  defp single_min_data_2() do
    [
      [price: 15, volume: 0.2, time: 1_616_436_301],
      [price: 17, volume: 0.6, time: 1_616_436_302],
      [price: 15, volume: 12, time: 1_616_436_303],
      [price: 15, volume: 150, time: 1_616_436_303],
      [price: 12, volume: 1.5, time: 1_616_436_314],
      [price: 1, volume: 1.6, time: 1_616_436_316],
      [price: 24, volume: 1.7, time: 1_616_436_322],
      [price: 167, volume: 19, time: 1_616_436_346],
      [price: 0.3, volume: 15, time: 1_616_436_347],
      [price: 167.5, volume: 13, time: 1_616_436_347],
      [price: 12, volume: 13, time: 1_616_436_352],
      [price: 11, volume: 17, time: 1_616_436_355],
      [price: 11, volume: 11, time: 1_616_436_358],
      [price: 18.11, volume: 1125, time: 1_616_436_359]
    ]
  end
end
