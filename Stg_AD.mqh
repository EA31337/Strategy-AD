//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements AD strategy. Based on A/D (Accumulation/Distribution) indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_AD.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __AD_Parameters__ = "-- AD strategy params --";  // >>> AD <<<
INPUT int AD_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32,H4=64...)
INPUT ENUM_TRAIL_TYPE AD_TrailingStopMethod = 3;     // Trail stop method
INPUT ENUM_TRAIL_TYPE AD_TrailingProfitMethod = 22;  // Trail profit method
INPUT int AD_Shift = 0;                              // Shift (relative to the current bar, 0 - default)
INPUT double AD_SignalOpenLevel = 0.0004;            // Signal open level (>0.0001)
INPUT int AD_SignalBaseMethod = 0;                   // Signal base method (0-1)
INPUT int AD_SignalOpenMethod1 = 0;                  // Open condition 1 (0-1023)
INPUT int AD_SignalOpenMethod2 = 0;                  // Open condition 2 (0-)
INPUT double AD_SignalCloseLevel = 0.0004;           // Signal close level (>0.0001)
INPUT ENUM_MARKET_EVENT AD_SignalCloseMethod1 = 0;   // Signal close method 1
INPUT ENUM_MARKET_EVENT AD_SignalCloseMethod2 = 0;   // Signal close method 2
INPUT double AD_MaxSpread = 6.0;                     // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_AD_Params : Stg_Params {
  unsigned int AD_Period;
  ENUM_APPLIED_PRICE AD_Applied_Price;
  int AD_Shift;
  ENUM_TRAIL_TYPE AD_TrailingStopMethod;
  ENUM_TRAIL_TYPE AD_TrailingProfitMethod;
  double AD_SignalOpenLevel;
  long AD_SignalBaseMethod;
  long AD_SignalOpenMethod1;
  long AD_SignalOpenMethod2;
  double AD_SignalCloseLevel;
  ENUM_MARKET_EVENT AD_SignalCloseMethod1;
  ENUM_MARKET_EVENT AD_SignalCloseMethod2;
  double AD_MaxSpread;

  // Constructor: Set default param values.
  Stg_AD_Params()
      : AD_Shift(::AD_Shift),
        AD_TrailingStopMethod(::AD_TrailingStopMethod),
        AD_TrailingProfitMethod(::AD_TrailingProfitMethod),
        AD_SignalOpenLevel(::AD_SignalOpenLevel),
        AD_SignalBaseMethod(::AD_SignalBaseMethod),
        AD_SignalOpenMethod1(::AD_SignalOpenMethod1),
        AD_SignalOpenMethod2(::AD_SignalOpenMethod2),
        AD_SignalCloseLevel(::AD_SignalCloseLevel),
        AD_SignalCloseMethod1(::AD_SignalCloseMethod1),
        AD_SignalCloseMethod2(::AD_SignalCloseMethod2),
        AD_MaxSpread(::AD_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_AD : public Strategy {
 public:
  Stg_AD(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_AD *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_AD_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_AD_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_AD_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_AD_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_AD_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_AD_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_AD_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    IndicatorParams ad_iparams(10, INDI_AD);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_AD(ad_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.AD_SignalBaseMethod, _params.AD_SignalOpenMethod1, _params.AD_SignalOpenMethod2,
                       _params.AD_SignalCloseMethod1, _params.AD_SignalCloseMethod2, _params.AD_SignalOpenLevel,
                       _params.AD_SignalCloseLevel);
    sparams.SetStops(_params.AD_TrailingProfitMethod, _params.AD_TrailingStopMethod);
    sparams.SetMaxSpread(_params.AD_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_AD(sparams, "AD");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double ad_0 = ((Indi_AD *)this.Data()).GetValue(0);
    double ad_1 = ((Indi_AD *)this.Data()).GetValue(1);
    double ad_2 = ((Indi_AD *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level == EMPTY) _signal_level = GetSignalOpenLevel();
    switch (_cmd) {
      // Buy: indicator growth at downtrend.
      case ORDER_TYPE_BUY:
        _result = ad_0 >= ad_1 + _signal_level && Chart().GetClose(0) <= Chart().GetClose(1);
        if (METHOD(_signal_method, 0)) _result &= Open[CURR] > Close[CURR];
        break;
      // Sell: indicator fall at uptrend.
      case ORDER_TYPE_SELL:
        _result = ad_0 <= ad_1 - _signal_level && Chart().GetClose(0) >= Chart().GetClose(1);
        if (METHOD(_signal_method, 0)) _result &= Open[CURR] < Close[CURR];
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
