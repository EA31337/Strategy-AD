/**
 * @file
 * Implements AD strategy. Based on A/D (Accumulation/Distribution) indicator.
 */

// User input params.
INPUT_GROUP("AD strategy: strategy params");
INPUT float AD_LotSize = 0;                // Lot size
INPUT int AD_SignalOpenMethod = 2;         // Signal open method
INPUT int AD_SignalOpenFilterMethod = 36;  // Signal open filter method (-127-127)
INPUT int AD_SignalOpenFilterTime = 3;     // Signal open filter time (-255-255)
INPUT float AD_SignalOpenLevel = 0.02f;    // Signal open level
INPUT int AD_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int AD_SignalCloseMethod = 2;        // Signal close method
INPUT int AD_SignalCloseFilter = 0;        // Signal close filter (-127-127)
INPUT float AD_SignalCloseLevel = 0.02f;   // Signal close level
INPUT int AD_PriceStopMethod = 3;          // Price stop method
INPUT float AD_PriceStopLevel = 2;         // Price stop level
INPUT int AD_TickFilterMethod = 32;        // Tick filter method
INPUT float AD_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short AD_Shift = 0;                  // Shift (relative to the current bar, 0 - default)
INPUT float AD_OrderCloseLoss = 80;        // Order close loss
INPUT float AD_OrderCloseProfit = 80;      // Order close profit
INPUT int AD_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("AD strategy: AD indicator params");
INPUT int AD_Indi_AD_Shift = 0;                                      // Shift
INPUT ENUM_IDATA_SOURCE_TYPE AD_Indi_AD_SourceType = IDATA_BUILTIN;  // Source type

// Structs.
// Defines struct with default user strategy values.
struct Stg_AD_Params_Defaults : StgParams {
  Stg_AD_Params_Defaults()
      : StgParams(::AD_SignalOpenMethod, ::AD_SignalOpenFilterMethod, ::AD_SignalOpenLevel, ::AD_SignalOpenBoostMethod,
                  ::AD_SignalCloseMethod, ::AD_SignalCloseFilter, ::AD_SignalCloseLevel, ::AD_PriceStopMethod,
                  ::AD_PriceStopLevel, ::AD_TickFilterMethod, ::AD_MaxSpread, ::AD_Shift) {
    Set(STRAT_PARAM_LS, AD_LotSize);
    Set(STRAT_PARAM_OCL, AD_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, AD_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, AD_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, AD_SignalOpenFilterTime);
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_AD : public Strategy {
 public:
  Stg_AD(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_AD *Init(ENUM_TIMEFRAMES _tf = NULL) {
    // Initialize strategy initial values.
    Stg_AD_Params_Defaults stg_ad_defaults;
    StgParams _stg_params(stg_ad_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_ad_m1, stg_ad_m5, stg_ad_m15, stg_ad_m30, stg_ad_h1, stg_ad_h4,
                             stg_ad_h8);
#endif
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_AD(_stg_params, _tparams, _cparams, "AD");
    return _strat;
  }

  /**
   * Event on strategy's init.
   */
  void OnInit() {
    IndiADParams ad_params(::AD_Indi_AD_Shift);
#ifdef __resource__
    ad_params.SetCustomIndicatorName("::" + STG_AD_INDI_FILE);
#endif
    ad_params.SetDataSourceType(AD_Indi_AD_SourceType);
    ad_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
    SetIndicator(new Indi_AD(ad_params));
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_AD *_indi = GetIndicator();
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi.IsIncByPct(_level, 0, 0, 3);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi.IsDecByPct(-_level, 0, 0, 3);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};
