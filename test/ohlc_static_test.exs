defmodule OHLCStaticTest do
  use ExUnit.Case

  import OHLC
  import OHLCHelper

  doctest OHLC

  test "Candle appending" do
    trades_1 = single_min_data_1()
    {:ok, data} = create_candles(trades_1, :minute)

    candle = Enum.at(data["candles"], 0)

    trades_2 = single_min_data_1()
    {:ok, data} = create_candles(trades_2, :minute, previous_candle: candle)

    assert(
      length(data["candles"]) === 1 and
        Enum.at(data["candles"], 0)["open"] ===
          Enum.at(trades_1, 0)[:price] |> format_to_float() and
        Enum.at(data["candles"], 0)["close"] ===
          Enum.at(trades_2, -1)[:price] |> format_to_float() and
        Enum.at(data["candles"], 0)["volume"] ===
          calculate_total_volume_trades(trades_1 ++ trades_2)
    )
  end

  test "Must contain one single minute candles" do
    trades_1 = single_min_data_1()
    {:ok, data} = create_candles(trades_1, :minute)

    candle = Enum.at(data["candles"], 0)

    trades_2 = single_min_data_2()
    {:ok, data} = create_candles(trades_2, :minute, previous_candle: candle)

    assert(
      length(data["candles"]) === 1 and
        Enum.at(data["candles"], 0)["open"] ===
          Enum.at(trades_1, 0)[:price] |> format_to_float() and
        Enum.at(data["candles"], 0)["close"] ===
          Enum.at(trades_2, -1)[:price] |> format_to_float() and
        Enum.at(data["candles"], 0)["volume"] ===
          calculate_total_volume_trades(trades_1 ++ trades_2)
    )
  end

  test "Must contain only single one minute candle" do
    {:ok, data} = create_candles(single_minute_candle_data(), :minute)

    assert length(data["candles"]) === 1
  end

  test "Must contain two one minute candles" do
    {:ok, data} = create_candles(two_one_minute_candles(), :minute)

    assert length(data["candles"]) === 2
  end

  test "Must contain two hourly candles" do
    trades = single_hourly_candle_1() ++ single_hourly_candle_2()
    {:ok, data} = create_candles(trades, :hour, [:skip_no_trades])

    assert length(data["candles"]) === 2
  end

  test "First candles high = 167.5000" do
    {:ok, data} = create_candles(single_minute_candle_data(), :minute)

    assert Enum.at(data["candles"], 0)["high"] === 167.5
  end

  test "First candles low = 0.3000" do
    {:ok, data} = create_candles(single_minute_candle_data(), :minute)

    assert Enum.at(data["candles"], 0)["low"] === 0.3
  end

  test "First candles open = 15.5000" do
    {:ok, data} = create_candles(single_minute_candle_data(), :minute)

    assert Enum.at(data["candles"], 0)["open"] === 15.0
  end

  test "First candles close = 11.1100" do
    {:ok, data} = create_candles(single_minute_candle_data(), :minute)

    assert Enum.at(data["candles"], 0)["close"] === 11.11
  end

  test "Single daily candles" do
    trades = single_daily_candle_1()

    {:ok, data} = create_candles(trades, :day)

    assert(
      length(data["candles"]) === 1 and
        Enum.at(data["candles"], 0)["open"] === Enum.at(trades, 0)[:price] and
        Enum.at(data["candles"], 0)["close"] === Enum.at(trades, -1)[:price] and
        Enum.at(data["candles"], 0)["volume"] === calculate_total_volume_trades(trades)
    )
  end

  test "Single weekly candle" do
    trades = single_weekly_candle_1()

    {:ok, data} = create_candles(trades, :week, [:skip_no_trades])

    assert(
      length(data["candles"]) === 1 and
        Enum.at(data["candles"], 0)["open"] === Enum.at(trades, 0)[:price] and
        Enum.at(data["candles"], 0)["close"] === Enum.at(trades, -1)[:price] and
        Enum.at(data["candles"], 0)["volume"] === calculate_total_volume_trades(trades)
    )
  end

  # Error tests

  test "Data key not correct and must return an error" do
    case create_candles(data_key_value_wrong(), :minute, validate_trades: true) do
      {:error, _} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

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

  defp calculate_total_volume_trades(trades) do
    Enum.reduce(trades, fn trade, acc ->
      volume_formatted = format_to_float(trade[:volume])

      if is_float(acc) do
        acc + volume_formatted
      else
        format_to_float(acc[:volume]) + volume_formatted
      end
    end)
    |> Float.round(4)
  end

  # Success return data items.
  defp single_minute_candle_data do
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
      [price: 11.11, volume: 1125, time: 1_616_436_359]
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

  defp two_one_minute_candles() do
    items = [
      [price: 15, volume: 0.2, time: 1_616_436_287],
      [price: 17, volume: 0.6, time: 1_616_436_299],
      [price: 17, volume: 0.6, time: 1_616_436_300]
    ]

    items ++ single_minute_candle_data()
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
      [price: 130.0, volume: 1, time: 1_616_439_600]
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

  defp single_daily_candle_1 do
    [
      [price: 125.54, volume: 0.1, time: 1_616_633_999],
      [price: 125.32, volume: 1.4, time: 1_616_641_905],
      [price: 125.12, volume: 1.9, time: 1_616_674_974],
      [price: 126.877, volume: 15, time: 1_616_702_514],
      [price: 19.3, volume: 19.43, time: 1_616_709_599]
    ]
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

  # Error return data items.
  defp data_key_value_wrong() do
    [
      [price: 15, volume: 15, time: 1_615_896_167],
      [price: 15, volume: 15, timex: 1_615_896_167]
    ]
  end

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
