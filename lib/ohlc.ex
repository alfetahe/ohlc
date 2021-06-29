defmodule OHLC do
  @moduledoc """
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
  - `:pair` - Adds the pair name to the returned outputs metadata.
  """
  @type opts :: [
          {:forward_fill, boolean()}
          | {:validate_trades, boolean()}
          | {:previous_candle, candle()}
          | {:pair, atom() | binary()}
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

  @doc """
  Coverts candles to new timeframe.

  Parameters:

  `candles` - A list of candles.
  `timeframe`-  Must be higher then the existing candles timeframe.
  For example if candles were previously created using :hour timeframe
  then the provided timeframe cannot be :minute.

  Returns a tuple containing the list of candles with converted timeframe.
  """
  @spec convert_timeframe(candles(), timeframe()) :: {:ok, candles()}
  def convert_timeframe(candles, timeframe) do
    candles = timeframe_conv_loop(candles, timeframe, [], 0)

    {:ok, candles}
  end

  @doc """
  Merges candle into another candle.

  If main candles `:stime` is 0 then fallback
  to the merge_child `:stime`.

  Parameters:
  - `main_candle` - Candle which will be merged into.
  - `merge_candle` - Candle which will be merged. It is important to
  have etime less than first candle. Meaning both candles should stay
  in the same timeframe.
  """
  @spec merge_child(candle(), candle()) :: {:ok, candle()} | {:error, binary()}
  def merge_child(main_candle, merge_candle) do
    if main_candle[:etime] > merge_candle[:etime] do
      candle = merge_single_candle(main_candle, merge_candle)

      {:ok, candle}
    else
      {:error, "Second candle's etime cannot be higher then first."}
    end
  end

  defp timeframe_conv_loop([chd | ctl], timeframe, [cchd | cctl] = conv_candles, active_stamp) do
    conv_candles =
      if chd[:stime] >= active_stamp do
        new_candle = set_conv_candle(chd, timeframe)

        [new_candle | conv_candles]
      else
        updated_candle = merge_single_candle(cchd, chd)

        [updated_candle | cctl]
      end

    active_stamp = set_active_conv_stamp(chd[:stime], active_stamp, timeframe)

    timeframe_conv_loop(ctl, timeframe, conv_candles, active_stamp)
  end

  defp timeframe_conv_loop([chd | ctl], timeframe, [], active_stamp) do
    active_stamp = set_active_conv_stamp(chd[:stime], active_stamp, timeframe)

    new_candle = set_conv_candle(chd, timeframe)
    conv_candles = [new_candle]

    timeframe_conv_loop(ctl, timeframe, conv_candles, active_stamp)
  end

  defp timeframe_conv_loop([], _timeframe, conv_candles, _active_stamp) do
    conv_candles
  end

  defp set_active_conv_stamp(candle_stamp, active_stamp, timeframe) do
    if candle_stamp > active_stamp do
      get_time_rounded(candle_stamp, timeframe, type: :up)
    else
      active_stamp
    end
  end

  defp set_conv_candle(chd, timeframe) do
    chd
    |> Map.put(:stime, get_time_rounded(chd[:stime], timeframe, type: :down))
    |> Map.put(:etime, get_time_rounded(chd[:stime], timeframe, type: :up))
  end

  defp merge_single_candle(main_candle, merge_candle) do
    main_candle
    |> Map.update(:volume, 0, fn vol -> (vol + merge_candle[:volume]) |> Float.round(4) end)
    |> Map.update(:trades, 0, fn trades -> trades + merge_candle[:trades] end)
    |> Map.update(:high, 0, fn high ->
      if high < merge_candle[:high], do: merge_candle[:high], else: high
    end)
    |> Map.update(:low, 0, fn low ->
      if low < merge_candle[:low] and low !== 0, do: low, else: merge_candle[:low]
    end)
    |> Map.put(:close, merge_candle[:close])
    |> Map.update(:type, nil, fn _type ->
      get_candle_type(main_candle[:open], merge_candle[:close])
    end)
    |> Map.update(:open, 0, fn open -> if open === 0, do: merge_candle[:open], else: open end)
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
      :candles => loop_trades(trades, candles, timeframe, opts) |> Enum.reverse()
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
          candle = create_candle(formatted_trade_data, timeframe)
          [[candle] ++ candles_body, trades_tail]

        # Updates last candle.
        dates_match === :eq ->
          updated_candle = update_candle(candles_head, formatted_trade_data)
          [[updated_candle] ++ candles_body, trades_tail]

        # Creates new candle or candles.
        dates_match === :lt or dates_match === :gt or dates_match === :empty_first_date ->
          case opts[:forward_fill] do
            true ->
              copy_or_create_loop([candles_head | candles_body], trades, timeframe)

            _ ->
              candle = create_candle(formatted_trade_data, timeframe)
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
            get_time_rounded(candles_head[:etime], timeframe, type: :up),
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
  defp create_candle(trade, timeframe) do
    type = get_candle_type(trade[:price], trade[:price])

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
  defp update_candle(candle, trade) do
    type = get_candle_type(candle[:open], trade[:price])

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
