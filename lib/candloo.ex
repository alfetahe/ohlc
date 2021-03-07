defmodule Candloo do
  @moduledoc """
  Documentation for Candloo.
  """

  alias Candloo.Candle

  def create_candles([[{:price, _}, {:volume, _}, {:time, _}, {:side, _}] | _] = trades, timeframe) do

    create_candle(trades, [], %Candle{}, timeframe)
  end

  defp create_candle([active_trade | trades_tail] = _trades, candles, previous_candle, timeframe) do

    trade_time = round(active_trade[:time]) |> DateTime.from_unix()
    trade_price_formatted = String.to_float(active_trade[:price])
    trade_volume_formatted = String.to_float(active_trade[:volume])

    candle = if previous_candle.processed === false or !timeframe_has_candle?(previous_candle, active_trade) do
      %Candle{
        open: trade_price_formatted,
        high: trade_price_formatted,
        low: trade_price_formatted,
        close: trade_price_formatted,
        volume: trade_volume_formatted,
        stime: trade_time,
        etime: get_etime(timeframe, trade_time),
        processed: true
      }
    else
      %{ previous_candle |
        high: max(trade_price_formatted, previous_candle.high),
        low: min(trade_price_formatted, previous_candle.low),
        volume: trade_volume_formatted + previous_candle.volume,
        processed: true
      }
    end

    create_candle(trades_tail, [candle | candles], candle, timeframe)
  end

  defp create_candle(trades, candles, _previous_candle, _timeframe) when length(trades) == 0, do: candles

  defp timeframe_has_candle?(previous_candle, trade) do

    trade_time = round(trade[:time]) |> DateTime.from_unix()

    previous_candle_etime = round(previous_candle[:etime]) |> DateTime.from_unix()

    case DateTime.compare(previous_candle_etime, trade_time) do
      :gt -> true
      :lt -> false
      :eq -> false
    end

  end

  defp get_etime(timeframe, trade_time) do

    candle_etime = %DateTime{
      year: trade_time.year,
      month: trade_time.month,
      day: 0,
      hour: 0,
      minute: 0,
      second: 0,
      time_zone: trade_time.time_zone,
      zone_abbr: trade_time.zone_abbr,
      utc_offset: trade_time.utc_offset,
      std_offset: trade_time.std_offset
    }

    case timeframe do
      :minute ->
        end_minutes = DateTime.add(trade_time, 60, :second)
        %{candle_etime | day: trade_time.day, hour: trade_time.hour, minute: end_minutes.minute, second: 0}
      :hour ->
        end_hour = DateTime.add(trade_time, 60, :minute)
        %{candle_etime | day: trade_time.day, hour: end_hour.hour, minute: 0, second: 0}
      :day ->
        end_day = DateTime.add(trade_time, 24, :hour)
        %{candle_etime | day: end_day.day, hour: 0, minute: 0, second: 0}
    end

  end

end
