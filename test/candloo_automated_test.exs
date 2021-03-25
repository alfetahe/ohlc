defmodule CandlooAutomatedTest do
  use ExUnit.Case
  doctest Candloo

  @timeframes [{:minute, 60}, {:hour, 3600}, {:day, 86_400}, {:week, 604_800}]

  # 2021-24-03 00:00:00 UTC +2
  @base_timestamp 1616623200

  @max_incrementor 45

  test "Test minute single candle 1" do
    trades = generate_single_candle_trades(@timeframes[:minute], 189.2, 94)

    a = 5 +2

  end

  def generate_single_candle_trades(timeframe, max_price, max_volume, timeframe_multiplier \\ 1) do
    max_price = max_price - @max_incrementor
    max_volume = max_volume - @max_incrementor

    base_timestamp = @base_timestamp + (timeframe * timeframe_multiplier)

    timestamp_addition = timeframe / @max_incrementor |> trunc()

    Enum.map(@max_incrementor..1, fn (numb) ->

      # Uneven number means selling and even buying side.
      side = case rem(numb, 2) do
        1 -> "s"
        0 -> "b"
      end

      [
        price: max_price + numb,
        volume: max_volume + numb,
        time: base_timestamp - (timestamp_addition * numb),
        side: side
      ]
    end)
  end

end
