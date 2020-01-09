//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_AD_EURUSD_H1_Params : Stg_AD_Params {
  Stg_AD_EURUSD_H1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H1;
    AD_Shift = 0;
    AD_TrailingStopMethod = 0;
    AD_TrailingProfitMethod = 0;
    AD_SignalOpenLevel = 0;
    AD_SignalBaseMethod = 0;
    AD_SignalOpenMethod1 = 0;
    AD_SignalOpenMethod2 = 0;
    AD_SignalCloseLevel = 0;
    AD_SignalCloseMethod1 = 0;
    AD_SignalCloseMethod2 = 0;
    AD_MaxSpread = 0;
  }
};
