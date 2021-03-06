defmodule Candloo do
  @moduledoc """
  Documentation for Candloo.
  """

  alias Candloo.Candle

  def calc_candles([[{:price, _}, {:volume, _}, {:time, _}, {:side, _}] | _] = trades, timeframe) do

    calc_candle(trades, [], %Candle{}, timeframe)
  end


  defp calc_candle([active_trade | trades_tail] = _trades, candles, previous_candle, timeframe) do

    candle = %Candle{
      open: String.to_float(active_trade[:price]),
      high: max(String.to_float(active_trade[:price]), previous_candle.high),
      close: String.to_float(active_trade[:price]),
      low: min(String.to_float(active_trade[:price]), previous_candle.low),
      volume: String.to_float(active_trade[:volume]) + previous_candle.volume,
      start_timestamp: round(active_trade[:time]) |> DateTime.from_unix()
    }

    calc_candle(trades_tail, [candle | candles], candle, timeframe)
  end

  defp calc_candle(trades, candles, _previous_candle, _timeframe) when length(trades) == 0 do
     candles
  end



end
