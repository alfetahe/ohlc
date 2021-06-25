# Candloo

Library for generating OHLC candles from trades.

## Installation

The package can be installed by adding `ohlc` to your
list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ohlc, "~> 1.0"}
  ]
end
```

## Example
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


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ohlc](https://hexdocs.pm/ohlc).

