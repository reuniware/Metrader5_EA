/*
Copyright 2020 FXcoder

This file is part of VP.

VP is free software: you can redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

VP is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with VP. If not, see
http://www.gnu.org/licenses/.
*/

#property copyright   "VP 9.0. © FXcoder"
#property link        "https://fxcoder.blogspot.com"
#property description "VP: Volume Profile Indicator"
#property strict
#property indicator_chart_window
#property indicator_plots 0

#include "VP-include/bsl.mqh"
#include "VP-include/enum/hg_coloring.mqh"
#include "VP-include/enum/hg_direction.mqh"
#include "VP-include/enum/point_scale.mqh"

#include "VP-include/enum/quantile.mqh"
#include "VP-include/volume/enum/vp_bar_style.mqh"
#include "VP-include/volume/enum/vp_hg_position.mqh"
#include "VP-include/volume/enum/vp_mode.mqh"
#include "VP-include/volume/enum/vp_range_mode.mqh"
#include "VP-include/volume/enum/vp_tick_price.mqh"
#include "VP-include/volume/enum/vp_time_shift.mqh"
#include "VP-include/volume/enum/vp_zoom.mqh"
#include "VP-include/volume/vp_indicator.mqh"


//#define input

#ifndef INPUT_GROUP
#define INPUT_GROUP ""
#endif

input ENUM_VP_MODE           Mode           = VP_MODE_PERIOD;        // Mode

input string                 g_per_mode_    = INPUT_GROUP;           // •••••••••• PERIOD MODE ••••••••••
input ENUM_TIMEFRAMES        RangePeriod    = PERIOD_D1;             // Range Period
input int                    RangeCount     = 20;                    // Range Count
input ENUM_VP_TIME_SHIFT     TimeShift      = VP_TIME_SHIFT_0;       // Time Zone Shift
input ENUM_HG_DIRECTION      DrawDirection  = HG_DIRECTION_RIGHT;    // Draw Direction
input ENUM_VP_ZOOM           ZoomType       = VP_ZOOM_AUTO_LOCAL;    // Zoom Type
input double                 ZoomCustom     = 0;                     // Custom Zoom

input string                 g_rng_mode_    = INPUT_GROUP;                     // •••••••••• RANGE MODE ••••••••••
input ENUM_VP_RANGE_MODE     RangeMode      = VP_RANGE_MODE_BETWEEN_LINES;     // Range Mode
input int                    RangeMinutes   = 1440;                            // Range Minutes
input ENUM_VP_HG_POSITION    HgPosition     = VP_HG_POSITION_CHART_RIGHT;      // Histogram Position

input string                 g_data_        = INPUT_GROUP;           // •••••••••• DATA ••••••••••
input ENUM_VP_SOURCE         DataSource     = VP_SOURCE_M1;          // Data Source

#ifdef __MQL4__
      ENUM_APPLIED_VOLUME    VolumeType     = VOLUME_TICK;           // Volume Type (always TICK in 4)

      ENUM_VP_TICK_PRICE     TickPriceType  = VP_TICK_PRICE_LAST;    // Price Type
      bool                   TickBid        = true;                  // Bid Price Changed
      bool                   TickAsk        = true;                  // Ask Price Changed
      bool                   TickLast       = true;                  // Last Price Changed
      bool                   TickVolume     = true;                  // Volume Changed
      bool                   TickBuy        = true;                  // Buy Deal
      bool                   TickSell       = true;                  // Sell Deal
#else
input ENUM_APPLIED_VOLUME    VolumeType     = VOLUME_TICK;           // Volume Type

input string                 g_tick_        = INPUT_GROUP;           // •••••••••• TICK ••••••••••
input ENUM_VP_TICK_PRICE     TickPriceType  = VP_TICK_PRICE_LAST;    // Price Type
input bool                   TickBid        = true;                  // Bid Price Changed
input bool                   TickAsk        = true;                  // Ask Price Changed
input bool                   TickLast       = true;                  // Last Price Changed
input bool                   TickVolume     = true;                  // Volume Changed
input bool                   TickBuy        = true;                  // Buy Deal
input bool                   TickSell       = true;                  // Sell Deal
#endif

input string                 g_calc_        = INPUT_GROUP;           // •••••••••• CALCULATION ••••••••••
input int                    ModeStep       = 100;                   // Mode Step (points)
input ENUM_POINT_SCALE       HgPointScale   = POINT_SCALE_10;        // Point Scale
input int                    Smooth         = 0;                     // Smooth Depth (0 => disable)

input string                 g_hg_          = INPUT_GROUP;           // •••••••••• HISTOGRAM ••••••••••
input ENUM_VP_BAR_STYLE      HgBarStyle     = VP_BAR_STYLE_LINE;     // Bar Style
input ENUM_HG_COLORING       HgColoring     = HG_COLORING_GRADIENT10;  // Coloring
input color                  HgColor        = C'128,160,192';        // Color 1 (Low Volume)
input color                  HgColor2       = C'128,160,192';        // Color 2 (High Volume)
input int                    HgLineWidth    = 1;                     // Line Width
input uint                   HgWidthPct     = 100;                   // Histogram Width (% of normal)

input string                 g_levels_      = INPUT_GROUP;         // •••••••••• LEVELS ••••••••••
input color                  ModeColor      = clrBlue;             // Mode Color
input color                  MaxColor       = clrNONE;             // Maximum Color
input int                    ModeLineWidth  = 1;                   // Mode Line Width

input color                  VwapColor      = clrNONE;             // VWAP Color

input ENUM_QUANTILE          Quantiles      = QUANTILE_NONE;       // Quantiles
input color                  QuantileColor  = clrChocolate;        // Quantile Color

input int                    StatLineWidth  = 1;                   // Quantile & VWAP Line Width
input ENUM_LINE_STYLE        StatLineStyle  = STYLE_DOT;           // Quantile & VWAP Line Style

input string                 g_lev_lines_   = INPUT_GROUP; // •••••••••• LEVEL LINES (range mode only) ••••••••••
input color                  ModeLevelColor = clrGreen;    // Mode Level Line Color (None=disable)
input int                    ModeLevelWidth = 1;           // Mode Level Line Width
input ENUM_LINE_STYLE        ModeLevelStyle = STYLE_SOLID; // Mode Level Line Style

input string                 g_service_     = INPUT_GROUP; // •••••••••• SERVICE ••••••••••
input bool                   ShowHorizon    = true;        // Show Data Horizon
input string                 Id             = "+vp";       // Identifier


CVPIndicator vpi_(
	Mode,

	//period mode
	RangePeriod,
	RangeCount,
	TimeShift,
	DrawDirection,
	ZoomType,
	ZoomCustom,

	// range mode
	RangeMode,
	RangeMinutes,
	HgPosition,

	// data
	DataSource,
	VolumeType,

	// tick
	TickPriceType,
	TickBid,
	TickAsk,
	TickLast,
	TickVolume,
	TickBuy,
	TickSell,

	// calc
	ModeStep,
	HgPointScale,
	Smooth,

	// hg
	HgBarStyle,
	HgColoring,
	// if colors are equal in color mode, make first transparent (none)
	(HgBarStyle == VP_BAR_STYLE_COLOR) && EnumHGColoringIsMulticolor(HgColoring) && (HgColor == HgColor2) ? _color.none : HgColor,

	HgColor2,
	HgLineWidth,
	HgWidthPct,

	// levels
	ModeColor,
	MaxColor,
	QuantileColor,
	VwapColor,
	ModeLineWidth,
	StatLineWidth,
	StatLineStyle,
	// do not show level lines in period mode
	Mode == VP_MODE_PERIOD ? _color.none : ModeLevelColor,
	ModeLevelWidth,
	ModeLevelStyle,
	Quantiles,

	// service
	ShowHorizon,
	Id
);


void OnInit()
{
	vpi_.init();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
	if (!_tf.is_enabled())
		return;

	_chartevent.init(id, lparam, dparam, sparam);
	vpi_.chart_event();
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[])
{
	_tf.enable();
	return(vpi_.calculate());
}

void OnTimer()
{
	if (!_tf.is_enabled())
		return;

	vpi_.timer();
}

void OnDeinit(const int reason)
{
	vpi_.deinit(reason);
}


/*
Последние изменения

9.0:
	* исправлено: не находятся моды, расположенные близко к краям, #67
	* добавлен параметр Quantiles для отображения некоторых квантилей, включая медиану, вместо только медианы, параметр MedianColor переименован QuantileColor
	* добавлен параметр HgColoring - способ расцветки гистограмм
	* добавлен параметр StatLineWidth - толщина линий статистики (VWAP, квантили), раньше была общей с толщиной мод
	* при Bar Style = Color если оба цвета одинаковы, то первый считается прозрачным
	* добавлен обязательный временной зазор между обновлениями (500 мс)

8.3:
	* исправлено: неверное отображение значений параметров Mode, RangeMode, HgPosition, #42
	* исправлено: смещение гистограм при появлении нового бара, #41

8.2:
	* нулевые хвосты обрезаются, особенно актуально при сглаживании и использовании типов отображения "контур" и "цвет", #28

8.1:
	* исправлено: небольшая ошибка сглаживания на концах гистограмм, #29
	* исправлено: не показываются моды и их уровни в режиме диапазона, #30
	* исправлено: не работает VWAP, экран заливается красным, #31

8.0:
	* исправлено: размер последней гистограммы выходит за данные, #26
	* исправлено: потеря точности при вычислении и отображении, #27
	* добавлен параметр TickPriceType для явного указания типа цены тиков, а также параметры их фильтрации: TickBid, TickAsk, TickLast, TickVolume, TickBuy, TickSell, #25
	* улучшен контроль за загрузкой отсутствующих данных
	* HgWidthPercent заменён на новый параметр HgWidthPct: процент нормальной ширины гистограммы (100% для периодов и 15% для диапазона, кроме отображения внутри), #8
	* режимы автомасштаба separate и overall переименованы в local и global соответственно
	* учёт цвета в режиме автомасштаба global, #24
*/
