/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_AD_Params_M15 : ADParams {
  Indi_AD_Params_M15() : ADParams(indi_ad_defaults, PERIOD_M15) { shift = 0; }
} indi_ad_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_AD_Params_M15 : StgParams {
  // Struct constructor.
  Stg_AD_Params_M15() : StgParams(stg_ad_defaults) {
    lot_size = 0;
    signal_open_method = -4;
    signal_open_filter = 24;
    signal_open_level = (float)7.0;
    signal_open_boost = 1;
    signal_close_method = 0;
    signal_close_level = (float)0.1;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_ad_m15;
