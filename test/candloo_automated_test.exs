defmodule CandlooAutomatedTest do
  use ExUnit.Case
  doctest Candloo

  @timeframes [{:minute, 60}, {:hour, 3600}, {:day, 86_400}, {:week, 604_800}]

  # 2021-22-03 00:00:00 UTC +0
  @base_timestamp 1_616_371_200

  # Minute Candles

  test "Test minute single candle" do
    assert(test_single_candle(:minute, 172.2, 368, 94, 0))
  end

  # test "Test minute multiple candles" do
  #   Enum.all?(1..1000, &test_single_candle(:minute, 133.1 * &1, 23.4 * &1, &1)) |> assert()
  # end

  # # Hourly candles

  # test "Test hourly single candle" do
  #   assert(test_single_candle(:hour, 1533, 24, 1))
  # end

  # test "Test hourly multiple candles" do
  #   Enum.all?(1..100, &test_single_candle(:hour, 48 * &1, 15 * &1, &1)) |> assert()
  # end

  # # Daily candles

  # test "Test daily single candle" do
  #   assert(test_single_candle(:day, 88.2, 12, 1))
  # end

  # test "Test daily multiple candles" do
  #   Enum.all?(1..100, &test_single_candle(:day, 142.2 * &1, 2430 * &1, &1)) |> assert()
  # end

  # # Weekly candles

  # test "Test weekly single candle" do
  #   assert(test_single_candle(:week, 19232, 15, 1))
  # end

  # test "Test weekly multiple candle" do
  #   Enum.all?(1..10, &test_single_candle(:week, 123 * &1, 153 * &1, &1)) |> assert()
  # end

  def test_single_candle(timeframe, min_price, max_price, volume, timeframe_multiplier) do
    {:ok, min_price} = Decimal.cast(min_price)
    min_price = Decimal.round(min_price, 4)

    {:ok, max_price} = Decimal.cast(max_price)
    max_price = Decimal.round(max_price, 4)

    trades =
      generate_single_candle_trades(
        @timeframes[timeframe],
        min_price,
        max_price,
        volume,
        timeframe_multiplier
      )

    {:ok, data} = Candloo.create_candles(trades, timeframe)

    length(data[:candles]) === 1 and
      Enum.at(data[:candles], 0).high === max_price |> Decimal.to_string() and
      Enum.at(data[:candles], 0).low === min_price |> Decimal.to_string() and
      Enum.at(data[:candles], 0).open === Enum.at(trades, 0)[:price] and
      Enum.at(data[:candles], 0).close === Enum.at(trades, -1)[:price] and
      Enum.at(data[:candles], 0).trades === length(trades) and
      Enum.at(data[:candles], 0).volume ===
        Decimal.mult(@timeframes[timeframe], volume) |> Decimal.round(4) |> Decimal.to_string() and
      Enum.at(data[:candles], 0).stime === Enum.at(trades, 0)[:time] and
      Enum.at(data[:candles], 0).etime ===
        Candloo.get_etime_rounded(Enum.at(trades, -1)[:time], timeframe, format: :stamp)
  end

  def generate_single_candle_trades(
        timeframe,
        min_price,
        max_price,
        volume,
        timeframe_multiplier \\ 1
      ) do
    price_range = Decimal.sub(max_price, min_price)

    timestamp_multipled = @base_timestamp + timeframe * timeframe_multiplier

    Enum.map(1..timeframe, fn numb ->
      # Uneven number means selling and even buying side.
      side =
        case rem(numb, 2) do
          1 -> "s"
          0 -> "b"
        end

      price =
        if numb !== timeframe do
          Decimal.div(price_range, numb)
          |> Decimal.round(4)
          |> Decimal.add(min_price)
          |> Decimal.to_string()
        else
          min_price |> Decimal.to_string()
        end

      [
        price: price,
        volume: volume,
        time: timestamp_multipled + numb,
        side: side
      ]
    end)
  end
end
