//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of AD Strategy based on AD (Accumulation/Distribution) indicator.
 *
 * Main principle: convergence/divergence.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iAD
 * - https://www.mql5.com/en/docs/indicators/iAD
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __AD_Parameters__ = "-- Settings for the Accumulation/Distribution indicator --"; // >>> AD <<<
#ifdef __input__ input #endif double AD_SignalLevel = 0.00000000; // Signal level
#ifdef __input__ input #endif string AD_SignalLevels = ""; // Signal level per timeframes.
#ifdef __input__ input #endif int AD_SignalMethod = 15; // Signal method (0-?)
#ifdef __input__ input #endif string AD_SignalMethods = ""; // Signal methods per timeframes (0-?)

class AD: public Strategy {
protected:

  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Accumulation/Distribution indicator.
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++)
      ad[index][i] = iAD(symbol, tf, i);
    break;
  }

  /**
   * Check if AD indicator is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, int tf = EMPTY, int open_method = 0, open_level = 0.0) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_AD, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_AD, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_AD, tf, 0.0);
    switch (cmd) {
      /*
        //2. Accumulation/Distribution - A/D
        //Main principle - convergence/divergence
        //Buy: indicator growth at downtrend
        //Sell: indicator fall at uptrend
        if (iAD(NULL,iad,0)>=iAD(NULL,iad,1) && iClose(NULL,iad2,0)<=iClose(NULL,iad2,1))
        {res=1;}
        if (iAD(NULL,iad,0)<=iAD(NULL,iad,1) && iClose(NULL,iad2,0)>=iClose(NULL,iad2,1))
        {res=-1;}
      */
      case OP_BUY:
        /*
          bool result = AD[period][CURR][LOWER] != 0.0 || AD[period][PREV][LOWER] != 0.0 || AD[period][FAR][LOWER] != 0.0;
          if ((signal_method &   1) != 0) result &= Open[CURR] > Close[CURR];
          if ((signal_method &   2) != 0) result &= !AD_On_Sell(period);
          if ((signal_method &   4) != 0) result &= AD_On_Buy(fmin(period + 1, M30));
          if ((signal_method &   8) != 0) result &= AD_On_Buy(M30);
          if ((signal_method &  16) != 0) result &= AD[period][FAR][LOWER] != 0.0;
          if ((signal_method &  32) != 0) result &= !AD_On_Sell(M30);
          */
      break;
      case OP_SELL:
        /*
          bool result = AD[period][CURR][UPPER] != 0.0 || AD[period][PREV][UPPER] != 0.0 || AD[period][FAR][UPPER] != 0.0;
          if ((signal_method &   1) != 0) result &= Open[CURR] < Close[CURR];
          if ((signal_method &   2) != 0) result &= !AD_On_Buy(period);
          if ((signal_method &   4) != 0) result &= AD_On_Sell(fmin(period + 1, M30));
          if ((signal_method &   8) != 0) result &= AD_On_Sell(M30);
          if ((signal_method &  16) != 0) result &= AD[period][FAR][UPPER] != 0.0;
          if ((signal_method &  32) != 0) result &= !AD_On_Buy(M30);
          */
      break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    return result;
  }
};
