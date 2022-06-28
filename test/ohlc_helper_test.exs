defmodule OHLCHelperTest do
  use ExUnit.Case

  import OHLCHelper

  doctest OHLCHelper

  test "get_timeframes" do
    timeframes = get_timeframes()
    cor_timeframes = [minute: 60, hour: 3600, day: 86_400, week: 604_800]

    assert timeframes === cor_timeframes
  end

  test "get_candle_type/2" do
    assert get_candle_type(1.5, 1.6) === :bullish
    assert get_candle_type(1.6, 1.5) === :bearish
  end

  test "trades_total_volume/1" do
    trades = [[volume: 1.1], [volume: 2.2], [volume: 3.3]]

    assert trades_total_volume(trades) === 6.6
  end
end
