/**
 * @file
 * Implements AD strategy. Based on A/D (Accumulation/Distribution) indicator.
 */

// User input params.
INPUT float AD_LotSize = 0;               // Lot size
INPUT int AD_SignalOpenMethod = 0;        // Signal open method
INPUT int AD_SignalOpenFilterMethod = 0;  // Signal open filter method (-7-7)
INPUT float AD_SignalOpenLevel = 0.0f;    // Signal open level
INPUT int AD_SignalOpenBoostMethod = 0;   // Signal open filter method
INPUT int AD_SignalCloseMethod = 0;       // Signal close method
INPUT float AD_SignalCloseLevel = 0.0f;   // Signal close level
INPUT int AD_PriceStopMethod = 0;         // Price stop method
INPUT float AD_PriceStopLevel = 0;        // Price stop level
INPUT int AD_TickFilterMethod = 0;        // Tick filter method
INPUT float AD_MaxSpread = 0;             // Max spread to trade (pips)
INPUT int AD_Shift = 0;                   // Shift (relative to the current bar, 0 - default)
INPUT int AD_OrderCloseTime = -10;        // Order close time in mins (>0) or bars (<0)

// Structs.

// Defines struct with default user strategy values.
struct Stg_AD_Params_Defaults : StgParams {
  Stg_AD_Params_Defaults()
      : StgParams(::AD_SignalOpenMethod, ::AD_SignalOpenFilterMethod, ::AD_SignalOpenLevel, ::AD_SignalOpenBoostMethod,
                  ::AD_SignalCloseMethod, ::AD_SignalCloseLevel, ::AD_PriceStopMethod, ::AD_PriceStopLevel,
                  ::AD_TickFilterMethod, ::AD_MaxSpread, ::AD_Shift, ::AD_OrderCloseTime) {}
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
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indicator *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      double _change_pc = Math::ChangeInPct(_indi[1][0], _indi[0][0]);
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: if the indicator is above zero and a column is green.
          // Buy: indicator growth at downtrend.
          _result &= _indi[0][0] > _indi[1][0] && _change_pc > _level;
          if (_method != 0) {
            // ... 2 consecutive columns are above level.
            if (METHOD(_method, 0)) _result &= Math::ChangeInPct(_indi[2][0], _indi[1][0]) > _level;
            // ... 3 consecutive columns are green.
            if (METHOD(_method, 1)) _result &= _indi[2][0] > _indi[3][0];
            // ... 4 consecutive columns are green.
            if (METHOD(_method, 2)) _result &= _indi[3][0] > _indi[4][0];
          }
          break;
        case ORDER_TYPE_SELL:
          // Sell: if the indicator is below zero and a column is red.
          // Sell: indicator fall at uptrend.
          _result &= _indi[0][0] < _indi[1][0] && _change_pc < _level;
          if (_method != 0) {
            // ... 2 consecutive columns are below level.
            if (METHOD(_method, 0)) _result &= Math::ChangeInPct(_indi[2][0], _indi[1][0]) < _level;
            // ... 3 consecutive columns are red.
            if (METHOD(_method, 1)) _result &= _indi[2][0] < _indi[3][0];
            // ... 4 consecutive columns are red.
            if (METHOD(_method, 2)) _result &= _indi[3][0] < _indi[4][0];
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indicator *_indi = Data();
    Chart *_chart = sparams.GetChart();
    double _trail = _level * _chart.GetPipSize();
    int _bar_count = (int)_level * 10;
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _change_pc = Math::ChangeInPct(_indi[1][0], _indi[0][0]);
    double _default_value = _chart.GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _price_offer = _chart.GetOpenOffer(_cmd);
    double _result = _default_value;
    ENUM_APPLIED_PRICE _ap = _direction > 0 ? PRICE_HIGH : PRICE_LOW;
    switch (_method) {
      case 1:
        _result = _indi.GetPrice(
            _ap, _direction > 0 ? _indi.GetHighest<double>(_bar_count) : _indi.GetLowest<double>(_bar_count));
        break;
      case 2:
        _result = Math::ChangeByPct(_price_offer, (float)_change_pc / _level / 100);
        break;
    }
    return (float)_result;
  }
};
