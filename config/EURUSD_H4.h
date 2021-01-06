/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct ADParams_H4 : ADParams {
  ADParams_H4() : ADParams(indi_ad_defaults, PERIOD_H4) { shift = 0; }
} indi_ad_h4;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_AD_Params_H4 : StgParams {
  // Struct constructor.
  Stg_AD_Params_H4() : StgParams(stg_ad_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)1;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)1;
    price_stop_method = 0;
    price_stop_level = 2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_ad_h4;
