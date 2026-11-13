import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../models/fx_models.dart';
import 'hourly_rate_ledger.dart';

/// Holds authentic daily fixing rates (ECB / HKMA, 2016–2026) and updates live
/// with Frankfurter timeseries responses.
class RealDailyLedger {
  RealDailyLedger._();

  static final RealDailyLedger instance = RealDailyLedger._();

  final Map<String, Map<String, double>> _memoryRates = {};
  List<String> _sortedDates = const [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<String> get allDates => _sortedDates;
  Map<String, Map<String, double>> get dailyRates => _memoryRates;

  Future<void> ensureLoaded() async {
    if (_isLoaded && _memoryRates.isNotEmpty) return;
    try {
      final jsonText = await rootBundle.loadString('assets/rates_2016_2026.json');
      loadFromJsonString(jsonText);
    } catch (_) {
      // Fallback gracefully if asset cannot be loaded in isolated unit tests
    }
  }

  bool loadFromJsonString(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      if (decoded.isEmpty) return false;
      _memoryRates.clear();
      decoded.forEach((date, value) {
        if (value is Map<String, dynamic>) {
          final dayMap = <String, double>{'USD': 1.0};
          value.forEach((currency, rateVal) {
            if (rateVal is num) {
              dayMap[currency.toUpperCase()] = rateVal.toDouble();
            }
          });
          _memoryRates[date] = dayMap;
        }
      });
      _sortedDates = _memoryRates.keys.toList()..sort();
      _isLoaded = _memoryRates.isNotEmpty;
      return _isLoaded;
    } catch (_) {
      return false;
    }
  }

  double? getRateOnDate(String dateStr, String baseCode, String targetCode) {
    final dayMap = _memoryRates[dateStr];
    if (dayMap == null) return null;
    final b = baseCode.toUpperCase();
    final t = targetCode.toUpperCase();
    if (b == t) return 1.0;

    final baseToUsd = dayMap[b] ?? (b == 'USD' ? 1.0 : null);
    final targetToUsd = dayMap[t] ?? (t == 'USD' ? 1.0 : null);
    if (baseToUsd == null || targetToUsd == null || baseToUsd <= 0.0) {
      return null;
    }
    return targetToUsd / baseToUsd;
  }

  void updateFromTimeseries(Map<String, Map<String, double>> timeseries) {
    if (timeseries.isEmpty) return;
    timeseries.forEach((date, rates) {
      final existing = Map<String, double>.from(_memoryRates[date] ?? const {});
      rates.forEach((k, v) {
        existing[k.toUpperCase()] = v;
      });
      existing['USD'] = 1.0;
      _memoryRates[date] = existing;
    });
    _sortedDates = _memoryRates.keys.toList()..sort();
    _isLoaded = _memoryRates.isNotEmpty;
  }

  List<RatePoint> buildRatePoints(
    String baseCode,
    String targetCode,
    TimeScale scale,
    double currentLiveRate, {
    int? nowMillis,
  }) {
    final nowTime = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    final b = baseCode.toUpperCase();
    final t = targetCode.toUpperCase();

    if (scale == TimeScale.oneDay) {
      return HourlyRateLedger.buildHourlyPoints(
        b,
        t,
        currentLiveRate,
        ledger: this,
        nowMillis: nowTime,
      );
    }

    if (_sortedDates.isEmpty) return const [];

    final int durationDays;
    switch (scale) {
      case TimeScale.oneWeek:
        durationDays = 8;
        break;
      case TimeScale.oneMonth:
        durationDays = 35;
        break;
      case TimeScale.oneYear:
        durationDays = 380;
        break;
      case TimeScale.fiveYears:
        durationDays = 5 * 366;
        break;
      case TimeScale.tenYears:
        durationDays = 11 * 366;
        break;
      case TimeScale.oneDay:
        durationDays = 1;
        break;
    }

    final minTime = nowTime - durationDays * 86400000;
    final filteredDates = _sortedDates.where((dStr) {
      final parsed = DateTime.tryParse(dStr);
      return parsed != null && parsed.millisecondsSinceEpoch >= minTime;
    }).toList();

    // Safety fallback if device clock is ahead of ledger tail
    final effectiveDates = filteredDates.length >= 2
        ? filteredDates
        : _sortedDates.sublist(
            (_sortedDates.length - scale.pointsCount).clamp(0, _sortedDates.length).toInt(),
          );

    final points = <RatePoint>[];
    for (final dStr in effectiveDates) {
      final rate = getRateOnDate(dStr, b, t);
      if (rate == null) continue;
      final parsed = DateTime.tryParse(dStr);
      final ts = parsed?.millisecondsSinceEpoch ?? nowTime;
      final labels = formatTimeLabels(ts, scale);
      points.add(
        RatePoint(
          timestampMs: ts,
          dateLabel: labels.$1,
          timeLabel: labels.$2,
          rate: rate,
        ),
      );
    }

    if (points.isNotEmpty) {
      final lastPt = points.last;
      if (nowTime - lastPt.timestampMs > 86400000) {
        final labels = formatTimeLabels(nowTime, scale);
        points.add(
          RatePoint(
            timestampMs: nowTime,
            dateLabel: labels.$1,
            timeLabel: labels.$2,
            rate: currentLiveRate,
          ),
        );
      }
    }

    return points;
  }

  static (String, String) formatTimeLabels(int timestampMs, TimeScale scale) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    switch (scale) {
      case TimeScale.oneDay:
      case TimeScale.oneWeek:
        return (DateFormat('MM/dd').format(dt), DateFormat('HH:mm').format(dt));
      case TimeScale.oneMonth:
        return (DateFormat('yyyy/MM/dd').format(dt), DateFormat('MM/dd').format(dt));
      case TimeScale.oneYear:
      case TimeScale.fiveYears:
      case TimeScale.tenYears:
        return (DateFormat('yyyy/MM/dd').format(dt), DateFormat('yyyy/MM').format(dt));
    }
  }
}
