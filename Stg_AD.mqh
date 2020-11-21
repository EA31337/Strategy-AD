/**
 * @file
 * Implements AD strategy. Based on A/D (Accumulation/Distribution) indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_AD.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float AD_LotSize = 0;                 // Lot size
INPUT int AD_SignalOpenMethod = 0;          // Signal open method
INPUT int AD_SignalOpenFilterMethod = 0;    // Signal open filter method
INPUT float AD_SignalOpenLevel = 0.0004f;   // Signal open level (>0.0001)
INPUT int AD_SignalOpenBoostMethod = 0;     // Signal open filter method
INPUT int AD_SignalCloseMethod = 0;         // Signal close method
INPUT float AD_SignalCloseLevel = 0.0004f;  // Signal close level (>0.0001)
INPUT int AD_PriceLimitMethod = 0;          // Price limit method
INPUT float AD_PriceLimitLevel = 2;         // Price limit level
INPUT int AD_TickFilterMethod = 0;          // Tick filter method
INPUT float AD_MaxSpread = 6.0;             // Max spread to trade (pips)
INPUT int AD_Shift = 0;                     // Shift (relative to the current bar, 0 - default)

// Structs.

// Defines struct with default user strategy values.
struct Stg_AD_Params_Defaults : StgParams {
  Stg_AD_Params_Defaults()
      : StgParams(::AD_SignalOpenMethod, ::AD_SignalOpenFilterMethod, ::AD_SignalOpenLevel, ::AD_SignalOpenBoostMethod,
                  ::AD_SignalCloseMethod, ::AD_SignalCloseLevel, ::AD_PriceLimitMethod, ::AD_PriceLimitLevel,
                  ::AD_TickFilterMethod, ::AD_MaxSpread, ::AD_Shift) {}
} stg_ad_defaults;

// Struct to define strategy parameters to override.
struct Stg_AD_Params : StgParams {
  StgParams sparams;

  // Struct constructors.
  Stg_AD_Params(StgParams &_sparams) : sparams(stg_ad_defaults) { sparams = _sparams; }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_AD : public Strategy {
 public:
  Stg_AD(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_AD *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    StgParams _stg_params(stg_ad_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_ad_m1, stg_ad_m5, stg_ad_m15, stg_ad_m30, stg_ad_h1, stg_ad_h4,
                               stg_ad_h8);
    }
    // Initialize indicator.
    ADParams ad_params(_tf);
    _stg_params.SetIndicator(new Indi_AD(ad_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_AD(_stg_params, "AD");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indicator *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid();
    bool _result = _is_valid;
    switch (_cmd) {
      // Buy: indicator growth at downtrend.
      case ORDER_TYPE_BUY:
        _result &= _indi[CURR].value[0] >= _indi[PREV].value[0] + _level && Chart().GetClose(0) <= Chart().GetClose(1);
        if (METHOD(_method, 0)) _result &= Open[CURR] > Close[CURR];
        break;
      // Sell: indicator fall at uptrend.
      case ORDER_TYPE_SELL:
        _result &= _indi[CURR].value[0] <= _indi[PREV].value[0] - _level && Chart().GetClose(0) >= Chart().GetClose(1);
        if (METHOD(_method, 0)) _result &= Open[CURR] < Close[CURR];
        break;
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indicator *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _bar_count = (int)_level * 10;
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    ENUM_APPLIED_PRICE _ap = _direction > 0 ? PRICE_HIGH : PRICE_LOW;
    switch (_method) {
      case 0:
        _result = _indi.GetPrice(_ap, _direction > 0 ? _indi.GetHighest(_bar_count) : _indi.GetLowest(_bar_count));
        break;
    }
    return (float)_result;
  }
};
