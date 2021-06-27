# OHLC

Library for generating OHLC candles from trades.


OHLC takes ordered list of trade events as input and 
outputs OHLC candles list. 

Library includes few options for appending candles to existing candles lists and more.

This library could be useful if you want to create your own charting engine or trading bot.

Documentation can be found here: https://hexdocs.pm/ohlc/1.0.0/OHLC.html

## Installation

The package can be installed by adding `ohlc` to your
list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ohlc, "~> 1.1"}
  ]
end
```

## Example usage
```elixir
defmodule Example do
  def calculate_ohlc() do
    trades = [
      [price: 12.21, volume: 0.98, time: 1616439921],
      [price: 12.54, volume: 12.1, time: 1616439931],
      [price: 12.56, volume: 18.3, time: 1616439952],
      [price: 18.9, volume: 12, time: 1616440004],
      [price: 11, volume: 43.1, time: 1616440025],
      [price: 18.322, volume: 43.1, time: 1616440028]
    ]

    case OHLC.create_candles(trades, :minute) do
      {:ok, data} -> IO.inspect data
      {:error, msg} -> IO.puts msg
    end
  end
end
```

## Example output
```elixir
%{
  candles: [
    %{
      close: 12.56,
      etime: 1616439959,
      high: 12.56,
      low: 12.21,
      open: 12.21,
      processed: true,
      stime: 1616439900,
      trades: 3,
      type: :bullish,
      volume: 31.38
    },
    %{
      close: 18.9,
      etime: 1616440019,
      high: 18.9,
      low: 18.9,
      open: 18.9,
      processed: true,
      stime: 1616439960,
      trades: 1,
      type: :bearish,
      volume: 12.0
    },
    %{
      close: 18.322,
      etime: 1616440079,
      high: 18.322,
      low: 11.0,
      open: 11.0,
      processed: true,
      stime: 1616440020,
      trades: 2,
      type: :bullish,
      volume: 86.2
    }
  ],
  pair: nil,
  timeframe: :minute
}
```

