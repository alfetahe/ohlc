defmodule CandlooAutomatedTest do
  use ExUnit.Case
  doctest Candloo

  @timeframes [{:minute, 60}, {:hour, 3600}, {:day, 86_400}, {:week, 604_800}]

  # 2021-22-03 00:00:00 UTC +0
  @base_timestamp 1_616_371_200

  # Minute Candles

  test "Test minute single candle" do
    assert(test_single_candle(:minute, 172.2, 368, 94.3, 0))
  end

  # test "Test minute multiple candles" do
  #   Enum.all?(0..1000, &test_single_candle(:minute, 83 + &1, 156 + &1, 2 + &1, &1)) |> assert()
  # end

  # # Hourly candles

  # test "Test hourly single candle" do
  #   assert(test_single_candle(:hour, 1533.45, 4893.232, 1.6, 0))
  # end

  # test "Test hourly multiple candles" do
  #   Enum.all?(0..100, &test_single_candle(:hour, 83.23 + &1, 384 + &1, 2.1 + &1, &1)) |> assert()
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
    # Create floats.
    min_price = min_price / 1
    max_price = max_price / 1

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
      Enum.at(data[:candles], 0).high === max_price |> Float.round(4) and
      Enum.at(data[:candles], 0).low === min_price |> Float.round(4) and
      Enum.at(data[:candles], 0).open === Enum.at(trades, 0)[:price] and
      Enum.at(data[:candles], 0).close === Enum.at(trades, -1)[:price] and
      Enum.at(data[:candles], 0).trades === length(trades) and
      Enum.at(data[:candles], 0).volume === (@timeframes[timeframe] * volume) |> Float.round(4) and
      Enum.at(data[:candles], 0).stime === Enum.at(trades, 0)[:time] and
      Enum.at(data[:candles], 0).etime === Candloo.get_etime_rounded(Enum.at(trades, -1)[:time], timeframe, format: :stamp)
  end

  def generate_single_candle_trades(
        timeframe,
        min_price,
        max_price,
        volume,
        timeframe_multiplier \\ 1
      ) do
    price_range = (max_price - min_price) |> Float.round(4)

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
          (price_range / numb) + min_price |> Float.round(4)
        else
          min_price
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
