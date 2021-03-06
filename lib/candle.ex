defmodule Candloo.Candle do

  defstruct timeframe: 0, start_timestamp: 0, open: 0, high: 0, close: 0, low: nil, volume: 0

  @timeframes [minute: 60, hour: 3600, half_day: 43200, day: 86400, week: 604800]

  @spec minute :: integer()
  def minute, do: Keyword.get(@timeframes, :minute)

  @spec hour :: integer()
  def hour, do: Keyword.get(@timeframes, :hour)

  @spec half_day :: integer()
  def half_day, do: Keyword.get(@timeframes, :half_day)

  @spec day :: integer()
  def day, do: Keyword.get(@timeframes, :day)

  @spec week :: integer()
  def week, do: Keyword.get(@timeframes, :week)

end
