defmodule CandlooTest do
  use ExUnit.Case
  doctest Candloo

  test "Trades list does not contain all necessary keys and must return error" do
    error_trade_field_missing = [
      [price: "15", volume: "15", time: "1615896167", side: "b",],
       [price: "15", volume: "15", timez: "1615896167", side: "b",],
    ]

    response = Candloo.create_candles(error_trade_field_missing, :minute)

    case response do
      {:error} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

  test "testing" do

    data = [
      ## + 1min

      # 10.03.2021 18:34:36
       [price: "1", volume: "1", time: "1615394076.927681", side: "b",],
       # 10.03.2021 18:34:56
       [zprice: "1.5", volume: "1.5", time: "1615394096", side: "s",],

       # 10.03.2021 18:35:04
       [price: "2", volume: "2", time: "1615394104", side: "b",],
       # 10.03.2021 18:35:42
       [price: "2.5", volume: "2.5", time: "1615394142.927681", side: "b",],

       # 10.03.2021 18:36:12
       [price: "3", volume: "3", time: "1615394172.32434", side: "s",],
       # 10.03.2021 18:36:18
       [price: "3.5", volume: "3.5", time: "1615394178.927681", side: "b",],

      ## + 1hour

      # 10.03.2021 19:01:05
       [price: "4", volume: "4", time: "1615395665.32434", side: "b",],
      # 10.03.2021 19:23:15
       [price: "4.5", volume: "4.5", time: "1615396995.12322", side: "b",],
       # 10.03.2021 19:59:01
       [price: "4.9", volume: "4.9", time: "1615399141.324", side: "b",],

       # 10.03.2021 20:55:12
       [price: "5", volume: "5", time: "1615402512", side: "b",],


      ## + 1day

      # 11.03.2021 09:33:19
       [price: "10", volume: "10", time: "1615447999", side: "b",],

       # 12.03.2021 11:23:21
       [price: "11", volume: "11", time: "1615541001", side: "b",],

       # 13.03.2021 14:05:11
       [price: "12", volume: "12", time: "1615637111", side: "b",],
       # 13.03.2021 23:55:42
       [price: "12.5", volume: "12.5", time: "1615672542", side: "b",],

       # 14.03.2021 23:59:42
       [price: "13", volume: "13", time: "1615759182", side: "b",],

      # 15.03.2021 01:02:34
       [price: "14", volume: "14", time: "1615762954", side: "b",],

      # 16.03.2021 14:02:47
       [price: "15", volume: "15", time: "1615896167", side: "b",],
    ]

  #  candles = Candloo.create_candles(data, :minute, [:no_trades_skip])
  end

end
