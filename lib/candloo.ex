defmodule Candloo do
  @moduledoc """
  Documentation for Candloo.
  """

  def calc_candles([[{:price, _}, {:volume, _}, {:side, _}, {:time, _}] | []] = _trades, [{:timeframe, _} | []] = _opts) do

  end

end
