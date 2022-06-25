defmodule OHLCFactoryTest do
  use ExUnit.Case

  import OHLCFactory

  doctest OHLCFactory

  test "gen_candles/3 amount" do
    amount = 11
    candles = gen_candles(:minute, amount)

    assert length(candles) === amount
  end

  test "gen_candles/3 stimes" do
    timeframe = :minute
    amount = 4
    candles = gen_candles(timeframe, amount)
    change_seconds = OHLCHelper.get_timeframes()[timeframe]

    curr_stamp = DateTime.utc_now() |> DateTime.to_unix()
    base_stime = OHLCHelper.get_time_rounded(curr_stamp, timeframe, type: :down)

    validations =
      Enum.map_reduce(candles, 1, fn candle, counter ->
        updated_stime =
          cond do
            counter === 1 -> base_stime
            true -> base_stime - counter * change_seconds
          end

        {updated_stime === candle[:stime], counter + 1}
      end)
      |> elem(0)

    assert Enum.all?(validations, & &1)
  end
end
