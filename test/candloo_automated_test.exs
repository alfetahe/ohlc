defmodule CandlooAutomatedTest do
  use ExUnit.Case
  doctest Candloo

  @timeframes [{:minute, 60}, {:hour, 3600}, {:day, 86_400}, {:week, 604_800}]

  # 2021-22-03 00:00:00 UTC +0
  @base_timestamp 1616371200

  # Minute Candles

  test "Test minute single candle" do
    assert(test_single_candle(:minute, 172.2, 368, 94.3, 0, 1))
  end

  test "Test minute multiple candles" do
    Enum.all?(0..1000, &test_single_candle(:minute, 83 + &1, 156 + &1, 2 + &1, &1, 1)) |> assert()
  end

  # Hourly candles

  test "Test hourly single candle" do
    assert(test_single_candle(:hour, 1533.45, 4893.232, 1.6, 0))
  end

  test "Test hourly multiple candles" do
    Enum.all?(0..10, &test_single_candle(:hour, 83.23 + &1, 384 + &1, 2.1 + &1, &1, 10)) |> assert()
  end

  # Daily candles

  test "Test daily single candle" do
    assert(test_single_candle(:day, 88.2, 112, 4.2, 0, 100))
  end

  test "Test daily multiple candles" do
    Enum.all?(0..3, &test_single_candle(:day, 142.2 + &1, 369.23 + &1, 0.3 + &1, &1, 100)) |> assert()
  end

  # # Weekly candles

  test "Test weekly single candle" do
    assert(test_single_candle(:week, 0.23, 0.42, 156.65, 0, 100))
  end

  test "Test weekly multiple candle" do
  #  Enum.all?(0..1, &test_single_candle(:week, 0.14 + &1, 0.68 + &1, 467 + &1, &1, 100)) |> assert()
  end

  def test_single_candle(timeframe, min_price, max_price, volume, timeframe_multiplier \\ 1, timeframe_divider \\ 1) do
    # Create floats.
    min_price = is_float(min_price) && Float.round(min_price, 4) || min_price / 1
    max_price = is_float(max_price) && Float.round(max_price, 4) || max_price / 1
    volume = is_float(volume) && Float.round(volume, 4) || volume / 1

    trades =
      generate_single_candle_trades(
        @timeframes[timeframe],
        min_price,
        max_price,
        volume,
        timeframe_multiplier,
        timeframe_divider
      )

    {:ok, data} = Candloo.create_candles(trades, timeframe)

    volume_to_check = ((@timeframes[timeframe] / timeframe_divider |> trunc()) * volume)
    volume_to_check = is_float(volume_to_check) && Float.round(volume_to_check, 4) || volume_to_check

    length(data[:candles]) === 1 and
      Enum.at(data[:candles], 0).high === max_price and
      Enum.at(data[:candles], 0).low === min_price and
      Enum.at(data[:candles], 0).open === Enum.at(trades, 0)[:price] and
      Enum.at(data[:candles], 0).close === Enum.at(trades, -1)[:price] and
      Enum.at(data[:candles], 0).trades === length(trades) and
      Enum.at(data[:candles], 0).volume === volume_to_check and
      Enum.at(data[:candles], 0).stime === Enum.at(trades, 0)[:time] and
      Enum.at(data[:candles], 0).etime === Candloo.get_etime_rounded(Enum.at(trades, -1)[:time], timeframe, format: :stamp)
  end

  def generate_single_candle_trades(
        timeframe,
        min_price,
        max_price,
        volume,
        timeframe_multiplier,
        timeframe_divider
      ) do
    price_range = (max_price - min_price) |> Float.round(4)

    timestamp_multipled = @base_timestamp + timeframe * timeframe_multiplier

    items_to_loop = timeframe / timeframe_divider |> trunc()

    Enum.map(1..items_to_loop, fn numb ->
      numb_multiplied = numb * timeframe_divider

      # Uneven number means selling and even buying side.
      side =
        case rem(numb, 2) do
          1 -> "s"
          0 -> "b"
        end

      price =
        cond do
          numb === 1 -> max_price
          numb_multiplied !== timeframe -> (price_range / numb_multiplied) + min_price |> Float.round(4)
          true -> min_price
        end

      price = is_float(price) && Float.round(price, 4) || price
      volume = is_float(volume) && Float.round(volume, 4) || volume

      [
        price: price,
        volume: volume,
        time: timestamp_multipled + numb_multiplied,
        side: side
      ]
    end)
  end
end
