defmodule CandlooStaticTest do
  use ExUnit.Case
  doctest Candloo

  test "Must contain only single one minute candle" do
    {:ok, data} = Candloo.create_candles(single_minute_candle_data(), :minute)

    assert length(data[:candles]) === 1
  end

  test "Must contain two one minute candles" do
    {:ok, data} = Candloo.create_candles(two_one_minute_candles(), :minute)

    assert length(data[:candles]) === 2
  end

  test "Must contain two hourly candles" do
    trades = single_hourly_candle_1() ++ single_hourly_candle_2()
    {:ok, data} = Candloo.create_candles(trades, :hour, [:skip_no_trades])

    assert length(data[:candles]) === 2
  end

  test "First candles high = 167.5000" do
    {:ok, data} = Candloo.create_candles(single_minute_candle_data(), :minute)

    assert Enum.at(data[:candles], 0).high === 167.5
  end

  test "First candles low = 0.3000" do
    {:ok, data} = Candloo.create_candles(single_minute_candle_data(), :minute)

    assert Enum.at(data[:candles], 0).low === 0.3
  end

  test "First candles open = 15.5000" do
    {:ok, data} = Candloo.create_candles(single_minute_candle_data(), :minute)

    assert Enum.at(data[:candles], 0).open === 15.0
  end

  test "First candles close = 11.1100" do
    {:ok, data} = Candloo.create_candles(single_minute_candle_data(), :minute)

    assert Enum.at(data[:candles], 0).close === 11.11
  end

  test "Single daily candles" do
    trades = single_daily_candle_1()

    {:ok, data} = Candloo.create_candles(trades, :day)

    assert(
      length(data[:candles]) === 1 and
        Enum.at(data[:candles], 0).open === Enum.at(trades, 0)[:price] and
        Enum.at(data[:candles], 0).close === Enum.at(trades, -1)[:price] and
        Enum.at(data[:candles], 0).volume === calculate_total_volume_trades(trades)
    )
  end

  test "Single weekly candle" do
    trades = single_weekly_candle_1()

    {:ok, data} = Candloo.create_candles(trades, :week, [:skip_no_trades])

    assert(
      length(data[:candles]) === 1 and
        Enum.at(data[:candles], 0).open === Enum.at(trades, 0)[:price] and
        Enum.at(data[:candles], 0).close === Enum.at(trades, -1)[:price] and
        Enum.at(data[:candles], 0).volume === calculate_total_volume_trades(trades)
    )
  end

  # Error tests

  test "Trades list is not sequenced by date and must return an error." do
    case Candloo.create_candles(data_not_sequenced(), :minute) do
      {:error, _} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

  test "Trades list does not contain all necessary keys and must return an error" do
    case Candloo.create_candles(error_in_keys(), :minute) do
      {:error, _} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

  test "Trades list value for :side is wrong and must return an error" do
    case Candloo.create_candles(data_key_value_wrong(), :minute) do
      {:error, _} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

  defp calculate_total_volume_trades(trades) do
    Enum.reduce(trades, fn trade, acc ->
      volume_formatted = Candloo.format_to_float(trade[:volume])

      if is_float(acc) do
        acc + volume_formatted
      else
        Candloo.format_to_float(acc[:volume]) + volume_formatted
      end
    end)
    |> Float.round(4)
  end

  # Success return data items.
  defp single_minute_candle_data do
    [
      [price: "15", volume: "0.2", time: "1616436301", side: "s"],
      [price: "17", volume: "0.6", time: "1616436302", side: "b"],
      [price: "15", volume: "12", time: "1616436303", side: "s"],
      [price: "15", volume: "150", time: "1616436303", side: "b"],
      [price: "12", volume: "1.5", time: "1616436314", side: "s"],
      [price: "1", volume: "1.6", time: "1616436316", side: "b"],
      [price: "24", volume: "1.7", time: "1616436322", side: "s"],
      [price: "167", volume: "19", time: "1616436346", side: "b"],
      [price: "0.3", volume: "15", time: "1616436347", side: "s"],
      [price: "167.5", volume: "13", time: "1616436347", side: "b"],
      [price: "12", volume: "13", time: "1616436352", side: "s"],
      [price: "11", volume: "17", time: "1616436355", side: "b"],
      [price: "11", volume: "11", time: "1616436358", side: "s"],
      [price: "11.11", volume: "1125", time: "1616436359", side: "b"]
    ]
  end

  defp two_one_minute_candles() do
    items = [
      [price: "15", volume: "0.2", time: "1616436287", side: "s"],
      [price: "17", volume: "0.6", time: "1616436299", side: "b"],
      [price: "17", volume: "0.6", time: "1616436300", side: "b"]
    ]

    items ++ single_minute_candle_data()
  end

  defp single_hourly_candle_1 do
    [
      [price: "125.54", volume: "0.1", time: "1616436299", side: "s"],
      [price: "125.32", volume: "1.4", time: "1616436734", side: "b"],
      [price: "125.12", volume: "1.9", time: "1616437334", side: "s"],
      [price: "126.877", volume: "15", time: "1616437394", side: "s"],
      [price: "19.3", volume: "19.43", time: "1616438474", side: "b"],
      [price: "119", volume: "0.002", time: "1616439119", side: "b"],
      [price: "119.654", volume: "0.89", time: "1616439120", side: "s"],
      [price: "129.32", volume: "1.42", time: "1616439302", side: "s"],
      [price: "130.0", volume: "1", time: "1616439600", side: "b"]
    ]
  end

  defp single_hourly_candle_2 do
    [
      [price: "12", volume: "22", time: "1616439602", side: "b"],
      [price: "12.56", volume: "18.3", time: "1616440572", side: "b"],
      [price: "18.9", volume: "12", time: "1616440692", side: "s"],
      [price: "11", volume: "43", time: "1616440759", side: "s"],
      [price: "199.3", volume: "8.93", time: "1616441583", side: "s"],
      [price: "2222", volume: "8", time: "1616441940", side: "b"],
      [price: "1234", volume: "8", time: "1616441952", side: "s"],
      [price: "44", volume: "7", time: "1616442512", side: "s"],
      [price: "98.4", volume: "0.5", time: "1616442679", side: "s"]
    ]
  end

  defp single_daily_candle_1 do
    [
      [price: 125.54, volume: "0.1", time: "1616633999", side: "s"],
      [price: 125.32, volume: "1.4", time: "1616641905", side: "b"],
      [price: 125.12, volume: "1.9", time: "1616674974", side: "s"],
      [price: 126.877, volume: "15", time: "1616702514", side: "s"],
      [price: 19.3, volume: "19.43", time: "1616709599", side: "b"]
    ]
  end

  defp single_weekly_candle_1 do
    [
      [price: 125.54, volume: "0.1", time: "1617010382", side: "s"],
      [price: 125.32, volume: "1.4", time: "1617096782", side: "b"],
      [price: 125.12, volume: "1.9", time: "1617183182", side: "s"],
      [price: 126.877, volume: "15", time: "1617269582", side: "s"],
      [price: 19.3, volume: "19.43", time: "1617355982", side: "b"]
    ]
  end

  # Error return data items.
  defp data_key_value_wrong() do
    [
      [price: "15", volume: "15", time: "1615896167", side: "b"],
      [price: "15", volume: "15", time: "1615896167", side: 3]
    ]
  end

  defp data_not_sequenced() do
    [
      [price: "15", volume: "15", time: "1615896667", side: "s"],
      [price: "15", volume: "15", time: "1616046310", side: "b"],
      [price: "15", volume: "15", time: "1615896167", side: "s"]
    ]
  end

  defp error_in_keys() do
    [
      [price: "15", volume: "15", time: "1615896167", side: "b"],
      [pricez: "15", volume: "15", time: "1615896168", side: "b"],
      [price: "15", volume: "15", timez: "1615896169", side: "b"]
    ]
  end
end
