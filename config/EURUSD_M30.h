/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_AD_Params_M30 : StgParams {
  // Struct constructor.
  Stg_AD_Params_M30() : StgParams(stg_ad_defaults) {
    lot_size = 0;
    signal_open_method = -1;
    signal_open_filter = 1;
    signal_open_level = 40;
    signal_open_boost = 0;
    signal_close_method = -3;
    signal_close_level = 40;
    price_stop_method = 0;
    price_stop_level = 2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_ad_m30;
