
# Change log

## v1.2.3 - 11.11.2022
### Added doctests and updated documentation.

## v1.2.2 - 30.06.2022
### Fixed
- Fixed OHLCFactory tests when validating the generated candles.

### Changed
- OHLCFactory generated candles will use the last closing price
as next candles opening price
- OHLCFactory default percetage change when generating candles is changed from 1 to 2

## v1.2.1 - 28.06.2022

### Added
- OHLCHelper test file
- Github Elixir action for CI

## v1.2.0 - 26.06.2022

### Added
- Factory module **OHLCFactory** which can be used to generate data.
- **gen_candles/3** function to generate OHLC candles.
- **gen_empty_candle/1** function to generate empty OHLC candle.
- **gen_trades/1** function to generate trades.

### Deprecated
- **OHLCHelper.gen_trades/6** use **OHLCFactory.gen_trades/1 instead**
- **OHLCHelper.generate_empty_candle/1** use **OHLCFactory.gen_empty_candle/1 instead**




