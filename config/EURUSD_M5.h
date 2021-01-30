/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_AD_Params_M5 : ADParams {
  Indi_AD_Params_M5() : ADParams(indi_ad_defaults, PERIOD_M5) {
    shift = 0;
  }
} indi_ad_m5;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_AD_Params_M5 : StgParams {
  // Struct constructor.
  Stg_AD_Params_M5() : StgParams(stg_ad_defaults) {
    lot_size = 0;
    signal_open_method = -1;
    signal_open_filter = 8;
    signal_open_level = (float)10.0;
    signal_open_boost = 1;
    signal_close_method = 0;
    signal_close_level = (float)30;
    price_stop_method = 1;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_ad_m5;
