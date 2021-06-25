defmodule OHLCStaticMinuteTest do
  use ExUnit.Case

  import OHLC

  doctest OHLC

  test "Single one minute candle test" do
    {:ok, data} = create_candles(single_min_data_1(), :minute)

    assert length(data[:candles]) === 1
  end

  test "Two one minute candles test" do
    {:ok, data} = create_candles(two_one_minute_candles(), :minute)

    assert length(data[:candles]) === 2
  end

  defp single_min_data_1 do
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

  defp two_one_minute_candles() do
    items = [
      [price: 15, volume: 0.2, time: 1_616_436_287],
      [price: 17, volume: 0.6, time: 1_616_436_299],
      [price: 17.9, volume: 0.6, time: 1_616_436_300]
    ]

    items ++ single_min_data_1()
  end
end
