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
      [price: 12, volume: 22, time: 1616439602],
      [price: 12.56, volume: 18.3, time: 1616440572],
      [price: 18.9, volume: 12, time: 1616440692],
      [price: 11, volume: 43, time: 1616440759]
    ]

    case OHLC.create_candles(trades, :minute, [validate_trades: true]) do
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
      close: 12.0,
      etime: 1616439659,
      high: 12.0,
      low: 12.0,
      open: 12.0,
      processed: true,
      stime: 1616439600,
      trades: 1,
      type: :bearish,
      volume: 22.0
    },
    %{
      close: 12.56,
      etime: 1616440619,
      high: 12.56,
      low: 12.56,
      open: 12.56,
      processed: true,
      stime: 1616440560,
      trades: 1,
      type: :bearish,
      volume: 18.3
    },
    %{
      close: 18.9,
      etime: 1616440739,
      high: 18.9,
      low: 18.9,
      open: 18.9,
      processed: true,
      stime: 1616440680,
      trades: 1,
      type: :bearish,
      volume: 12.0
    },
    %{
      close: 11.0,
      etime: 1616440799,
      high: 11.0,
      low: 11.0,
      open: 11.0,
      processed: true,
      stime: 1616440740,
      trades: 1,
      type: :bearish,
      volume: 43.0
    }
  ],
  pair: nil,
  timeframe: :minute
}
```

