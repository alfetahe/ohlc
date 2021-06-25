defmodule OHLC do
  @moduledoc """
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

  """

  import OHLCHelper

  @typedoc """
  Single trade.
  """
  @type trade :: [
          {:price, number()}
          | {:volume, number()}
          | {:time, number()}
        ]

  @typedoc """
  A list of trades.
  """
  @type trades :: [trade()]

  @typedoc """
  Single candle generated.
  """
  @type candle :: %{
          required(:open) => number(),
          required(:high) => number(),
          required(:low) => number(),
          required(:close) => number(),
          required(:volume) => number(),
          required(:trades) => number(),
          required(:stime) => number(),
          required(:etime) => number(),
          required(:type) => :bullish | :bearish | nil,
          optional(:processed) => boolean()
        }

  @typedoc """
  A list of candles.
  """
  @type candles :: [candle()]

  @typedoc """
  Available timeframes for `create_candles/3`
  """
  @type timeframe :: :minute | :hour | :day | :week

  @typedoc """
  Available options for `create_candles/3`
  - `:forward_fill` - When set true copies the previous candles closing price
  to the next candle if no trades happend to be in between.
  Useful when you don't want to get empty time gap between the generated candles.
  - `:validate_trades` - When set true all trades are being validated before
  generating the candles to avoid errors and misinformation.
  - `:previous_candle` - Trades are appended to the previous candle if possible
  before generating the new candles.
  """
  @type opts :: [
          {:forward_fill, boolean()}
          | {:validate_trades, boolean()}
          | {:previous_candle, candle()}
        ]

  @doc """
  Function for generating candles from trades and timeframe provided.

  Parameters:
  - `trades` - A list containing all the trades. Trades must be
  chronologically arranged(ASC) by the timestamp field.
  - `timeframe` - Timeframe for the candles.
  - `opts` - Option values for the data proccessing.

  Returns a tuple containing the metadata for the candles and a list
  of generated candles.
  """
  @spec create_candles(trades(), timeframe(), opts() | nil) ::
          {:ok,
           %{
             :pair => binary() | atom(),
             :timeframe => timeframe(),
             :candles => candles()
           }}
          | {:error, binary()}
  def create_candles(trades, timeframe, opts \\ []) do
    candles =
      cond do
        opts[:previous_candle] === %{} or opts[:previous_candle] === nil ->
          [generate_empty_candle()]

        true ->
          [opts[:previous_candle]]
      end

    construct_candles(candles, trades, timeframe, opts)
  end

  defp construct_candles(candles, trades, timeframe, opts) do
    if opts[:validate_trades] do
      case validate_data(candles, trades) do
        {:error, msg} ->
          {:error, msg}

        :ok ->
          set_return_data(candles, trades, timeframe, opts)
      end
    else
      set_return_data(candles, trades, timeframe, opts)
    end
  end

  defp set_return_data(candles, trades, timeframe, opts) do
    data = %{
      :pair => opts[:pair],
      :timeframe => timeframe,
      :candles => loop_trades(trades, candles, timeframe, opts)
    }

    {:ok, data}
  end

  # Loops thru trades and creates or updates candles.
  defp loop_trades(
         [trades_head | trades_tail] = trades,
         [candles_head | candles_body] = candles,
         timeframe,
         opts
       ) do
    formatted_trade_data = format_trade_data(trades_head)

    dates_match =
      dates_match_timeframe(candles_head[:etime], formatted_trade_data[:time], timeframe)

    [candles, trades_tail] =
      cond do
        # Appends new candle to the candles list without the unprocessed candle.
        !candles_head[:processed] ->
          candle = create_candle(formatted_trade_data, timeframe, candles_head[:close])
          [[candle] ++ candles_body, trades_tail]

        # Updates last candle.
        dates_match === :eq ->
          prev_candle = Enum.at(candles_body, 0)
          prev_close = if prev_candle, do: prev_candle[:close], else: 0

          updated_candle = update_candle(candles_head, formatted_trade_data, prev_close)
          [[updated_candle] ++ candles_body, trades_tail]

        # Creates new candle or candles.
        dates_match === :lt or dates_match === :gt or dates_match === :empty_first_date ->
          case opts[:forward_fill] do
            true ->
              copy_or_create_loop([candles_head | candles_body], trades, timeframe)

            _ ->
              candle = create_candle(formatted_trade_data, timeframe, candles_head[:close])
              [[candle] ++ candles, trades_tail]
          end
      end

    loop_trades(trades_tail, candles, timeframe, opts)
  end

  # Returns all candles.
  defp loop_trades(trades, candles, _timeframe, _no_trade_option) when length(trades) == 0,
    do: candles

  defp copy_or_create_loop(
         [candles_head | _candles_body] = candles,
         [trades_head | trades_tail] = trades,
         timeframe
       ) do
    trade_formatted = format_trade_data(trades_head)
    candles_head_etime_added = get_time_rounded(candles_head[:etime], timeframe, type: :jump)

    date_check =
      dates_match_timeframe(
        trade_formatted[:time],
        candles_head_etime_added,
        timeframe
      )

    cond do
      date_check === :eq or date_check === :lt ->
        candle = create_candle(trade_formatted, timeframe)
        [[candle] ++ candles, trades_tail]

      date_check === :gt ->
        copied_candle =
          forward_candle(
            candles_head[:close],
            candles_head_etime_added,
            candles_head_etime_added
          )

        candles = [copied_candle] ++ candles

        copy_or_create_loop(candles, trades, timeframe)
    end
  end

  defp forward_candle(last_price, stime, etime) do
    generate_empty_candle()
    |> Map.put(:open, last_price)
    |> Map.put(:close, last_price)
    |> Map.put(:stime, stime)
    |> Map.put(:etime, etime)
    |> Map.put(:processed, true)
  end

  # Creates new candle.
  defp create_candle(trade, timeframe, prev_close \\ nil) do
    type = if trade[:price] > prev_close, do: :bullish, else: :bearish

    generate_empty_candle()
    |> Map.put(:open, trade[:price])
    |> Map.put(:close, trade[:price])
    |> Map.put(:high, trade[:price])
    |> Map.put(:low, trade[:price])
    |> Map.put(:volume, trade[:volume])
    |> Map.put(:trades, 1)
    |> Map.put(:type, type)
    |> Map.put(:stime, get_time_rounded(trade[:time], timeframe, type: :down))
    |> Map.put(:etime, get_time_rounded(trade[:time], timeframe))
    |> Map.put(:processed, true)
  end

  # Returns updated candle.
  defp update_candle(candle, trade, prev_close) do
    type = if trade[:price] > prev_close, do: :bullish, else: :bearish

    %{
      candle
      | :close => trade[:price],
        :high => max(trade[:price], candle[:high]) |> Float.round(4),
        :low => min(trade[:price], candle[:low]) |> Float.round(4),
        :volume => (trade[:volume] + candle[:volume]) |> Float.round(4),
        :trades => 1 + candle[:trades],
        :type => type,
        :processed => true
    }
  end

  # Formats the trade data.
  defp format_trade_data(trade) do
    trade = Keyword.put(trade, :time, format_to_float(trade[:time]) |> round())
    trade = Keyword.put(trade, :price, format_to_float(trade[:price]) |> Float.round(4))
    trade = Keyword.put(trade, :volume, format_to_float(trade[:volume]) |> Float.round(4))

    trade
  end

  defp dates_match_timeframe(first_date, second_date, timeframe) do
    if first_date !== 0 do
      first_date = get_time_rounded(first_date, timeframe, format: :struct)
      second_date = get_time_rounded(second_date, timeframe, format: :struct)

      DateTime.compare(first_date, second_date)
    else
      :empty_first_date
    end
  end
end
