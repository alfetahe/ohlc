defmodule OHLCStaticTest do
  use ExUnit.Case

  import OHLC
  import OHLCHelper

  doctest OHLC

  test "Candle forward fill" do
    {:ok, data} = create_candles(forward_filling_data_1(), :hour, forward_fill: true)

    assert length(data[:candles]) === 12
  end

  test "Candle appending" do
    trades_1 = single_min_data_1()
    {:ok, data} = create_candles(trades_1, :minute)

    candle = Enum.at(data[:candles], 0)

    trades_2 = single_min_data_1()
    {:ok, data} = create_candles(trades_2, :minute, previous_candle: candle)

    assert length(data[:candles]) === 1
    assert Enum.at(data[:candles], 0)[:open] === Enum.at(trades_1, 0)[:price] |> format_to_float()

    assert Enum.at(data[:candles], 0)[:close] ===
             Enum.at(trades_2, -1)[:price] |> format_to_float()

    assert Enum.at(data[:candles], 0)[:volume] === trades_total_volume(trades_1 ++ trades_2)
  end

  test "Must contain one single minute candles" do
    trades_1 = single_min_data_1()
    {:ok, data} = create_candles(trades_1, :minute)

    candle = Enum.at(data[:candles], 0)

    trades_2 = single_min_data_2()
    {:ok, data} = create_candles(trades_2, :minute, previous_candle: candle)

    assert length(data[:candles]) === 1
    assert Enum.at(data[:candles], 0)[:open] === Enum.at(trades_1, 0)[:price] |> format_to_float()

    assert Enum.at(data[:candles], 0)[:close] ===
             Enum.at(trades_2, -1)[:price] |> format_to_float()

    assert Enum.at(data[:candles], 0)[:volume] === trades_total_volume(trades_1 ++ trades_2)
  end

  # Error tests

  test "Trades list is not sequenced by date and must return an error" do
    case create_candles(data_not_sequenced(), :minute, validate_trades: true) do
      {:error, _} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

  test "Trades list does not contain all necessary keys and must return an error" do
    case create_candles(error_in_keys(), :minute, validate_trades: true) do
      {:error, _} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

  def forward_filling_data_1() do
    [
      [price: "0.23", volume: "0.2", time: "1624613906"],
      [price: "0.23", volume: "0.2", time: "1624635506"],
      [price: "0.14", volume: "150.2", time: "1624649906"],
      [price: "0.193", volume: "3", time: "1624653506"]
    ]
  end

  def single_min_data_1 do
    [
      [price: "15", volume: "0.2", time: "1616436301"],
      [price: "17", volume: "0.6", time: "1616436302"],
      [price: "15", volume: "12", time: "1616436303"],
      [price: "15", volume: "150", time: "1616436303"],
      [price: "12", volume: "1.5", time: "1616436314"],
      [price: "1", volume: "1.6", time: "1616436316"],
      [price: "24", volume: "1.7", time: "1616436322"]
    ]
  end

  def single_min_data_2 do
    [
      [price: 167, volume: 19, time: 1_616_436_346],
      [price: 0.3, volume: 15, time: 1_616_436_347],
      [price: 165.7, volume: 13, time: 1_616_436_347],
      [price: 12, volume: 13, time: 1_616_436_352],
      [price: 11, volume: 17, time: 1_616_436_355],
      [price: 11, volume: 11, time: 1_616_436_358],
      [price: 11.11, volume: 1125, time: 1_616_436_359]
    ]
  end

  # Error return data items.
  defp data_not_sequenced() do
    [
      [price: 15, volume: 15, time: 1_615_896_667],
      [price: 15, volume: 15, time: 1_616_046_310],
      [price: 15, volume: 15, time: 1_615_896_167]
    ]
  end

  defp error_in_keys() do
    [
      [price: 15, volume: 15, time: 1_615_896_167],
      [pricez: 15, volume: 15, time: 1_615_896_168],
      [price: 15, volume: 15, timez: 1_615_896_169]
    ]
  end
end
