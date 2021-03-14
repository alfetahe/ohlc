defmodule CandlooTest do
  use ExUnit.Case
  doctest Candloo

  test "Trades list does not contain all necessary keys and must return error" do
    data = [
      [price: "15", volume: "15", time: "1615896167", side: "b",],
       [price: "15", volume: "15", timez: "1615896167", side: "b",],
    ]

    case Candloo.create_candles(data, :minute) do
      {:error, _} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

  test "Trades list value for :side is wrong and must return error" do
    data = [
      [price: "15", volume: "15", time: "1615896167", side: "b",],
       [price: "15", volume: "15", time: "1615896167", side: 3,],
    ]

    case Candloo.create_candles(data, :minute) do
      {:error, _} -> assert(true)
      {:ok, _} -> assert(false)
      _ -> assert(false)
    end
  end

end
