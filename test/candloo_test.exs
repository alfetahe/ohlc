defmodule CandlooTest do
  use ExUnit.Case
  doctest Candloo

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

  # Error return data items.
  def data_key_value_wrong() do
    [
      [price: "15", volume: "15", time: "1615896167", side: "b"],
      [price: "15", volume: "15", time: "1615896167", side: 3]
    ]
  end

  def data_not_sequenced() do
    [
      [price: "15", volume: "15", time: "1615896667", side: "s"],
      [price: "15", volume: "15", time: "1616046310", side: "b"],
      [price: "15", volume: "15", time: "1615896167", side: "s"]
    ]
  end

  def error_in_keys() do
    [
      [price: "15", volume: "15", time: "1615896167", side: "b"],
      [pricez: "15", volume: "15", time: "1615896168", side: "b"],
      [price: "15", volume: "15", timez: "1615896169", side: "b"]
    ]
  end

  # Success return data items.
end
