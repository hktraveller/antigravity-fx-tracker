import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../data/currency_catalog.dart';
import '../data/fx_api_client.dart';
import '../data/hourly_rate_ledger.dart';
import '../data/real_daily_ledger.dart';
import '../models/fx_models.dart';

class ExchangeRateRepository {
  ExchangeRateRepository({
    FxApiClient? apiClient,
    RealDailyLedger? dailyLedger,
  })  : _apiClient = apiClient ?? FxApiClient(),
        _dailyLedger = dailyLedger ?? RealDailyLedger.instance {
    _cachedRates.addAll(defaultRates);
  }

  final FxApiClient _apiClient;
  final RealDailyLedger _dailyLedger;

  static const Map<String, double> defaultRates = {
    'USD': 1.0,
    'HKD': 7.84444,
    'JPY': 159.70,
    'EUR': 0.90245,
    'GBP': 0.75440,
    'CNY': 6.6683,
    'SGD': 1.2859,
    'THB': 33.815,
    'TWD': 32.4131,
    'TRY': 50.258,
    'NZD': 1.7997,
    'AUD': 1.4661,
    'CAD': 1.4249,
    'VND': 25790.1,
    'KRW': 1334.1,
    'CHF': 0.83314,
    'MYR': 4.0785,
    'INR': 94.04,
    'PHP': 63.727,
    'IDR': 18253.0,
    'AED': 3.6725,
    'SEK': 9.9836,
    'BRL': 5.6169,
  };

  static const Map<String, double> _historicalRatios1Y = {
    'EUR': 0.9652,
    'HKD': 0.9924,
    'USD': 1.0000,
    'JPY': 0.9880,
    'GBP': 1.0170,
    'CNY': 1.0640,
    'TWD': 0.9650,
    'TRY': 0.8430,
    'SGD': 1.0180,
    'THB': 0.9610,
    'AUD': 1.0570,
    'CAD': 0.9870,
    'NZD': 0.9910,
    'KRW': 1.0990,
    'VND': 0.9850,
    'CHF': 1.0600,
  };

  static const Map<String, double> _historicalRatios5Y = {
    'TRY': 0.15,
    'JPY': 0.69,
    'EUR': 0.94,
    'GBP': 1.01,
    'HKD': 0.992,
    'CNY': 0.96,
    'TWD': 0.88,
    'KRW': 0.88,
    'THB': 0.92,
    'SGD': 1.04,
    'AUD': 0.96,
    'CAD': 0.92,
    'NZD': 0.86,
    'VND': 0.90,
    'CHF': 1.09,
  };

  static const Map<String, double> _historicalRatios10Y = {
    'TRY': 0.058,
    'JPY': 0.69,
    'EUR': 1.00,
    'GBP': 0.89,
    'HKD': 0.988,
    'CNY': 0.987,
    'TWD': 0.958,
    'KRW': 0.86,
    'THB': 0.98,
    'SGD': 1.06,
    'AUD': 0.94,
    'CAD': 0.93,
    'NZD': 0.84,
    'VND': 0.87,
    'CHF': 1.18,
  };

  final Map<String, double> _cachedRates = {};
  final Map<String, List<RatePoint>> _historicalCache = {};
  final Map<String, ({int fetchedMs, List<RatePoint> points})> _intradayCache =
      {};
  int _lastFetchEpochMs = 0;

  String lastUpdatedTimeString =
      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  String dataProviderName = 'Interbank FX & Central Banks';
  ApiConnectionStatus connectionStatus = ApiConnectionStatus.connecting;
  String? lastConnectionError;

  Future<void> init() async {
    await _dailyLedger.ensureLoaded();
  }

  Future<void> refreshRatesIfNeeded({
    bool force = false,
    int minIntervalMs = 3000,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force &&
        _lastFetchEpochMs > 0 &&
        (now - _lastFetchEpochMs) < minIntervalMs) {
      return;
    }
    await refreshRates();
  }

  Future<bool> refreshRates() async {
    _historicalCache.clear();
    _lastFetchEpochMs = DateTime.now().millisecondsSinceEpoch;

    String? primaryError;
    try {
      final primary = await _apiClient.fetchOpenErUsdRates();
      if (primary != null && primary.rates.isNotEmpty) {
        _cachedRates.addAll(primary.rates);
        _cachedRates['USD'] = 1.0;
        final dt = primary.timestampUnixSec != null
            ? DateTime.fromMillisecondsSinceEpoch(
                primary.timestampUnixSec! * 1000,
              )
            : DateTime.now();
        lastUpdatedTimeString = DateFormat('yyyy-MM-dd HH:mm').format(dt);
        dataProviderName = primary.providerName;
        connectionStatus = ApiConnectionStatus.live;
        lastConnectionError = null;
        return true;
      }
      primaryError = 'Empty response from open.er-api.com';
    } catch (e) {
      primaryError = e.toString();
    }

    try {
      final backup = await _apiClient.fetchFrankfurterLatest();
      if (backup != null && backup.rates.isNotEmpty) {
        _cachedRates.addAll(backup.rates);
        _cachedRates['USD'] = 1.0;
        lastUpdatedTimeString =
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
        dataProviderName = backup.providerName;
        connectionStatus = ApiConnectionStatus.live;
        lastConnectionError = null;
        return true;
      }
    } catch (e) {
      lastConnectionError = primaryError ?? e.toString();
    }

    connectionStatus = ApiConnectionStatus.fallback;
    dataProviderName = 'Offline Ledger Fallback';
    lastConnectionError ??= primaryError ?? 'Network unreachable';
    return false;
  }

  void clearHistoricalCache() {
    _historicalCache.clear();
    _intradayCache.clear();
    _lastFetchEpochMs = 0;
  }

  Map<String, double> getRatesSnapshot() => Map.unmodifiable(_cachedRates);

  double getRate(String baseCode, String targetCode) {
    final b = baseCode.toUpperCase();
    final t = targetCode.toUpperCase();
    if (b == t) return 1.0;
    final baseToUsd = _cachedRates[b] ?? defaultRates[b] ?? 1.0;
    final targetToUsd = _cachedRates[t] ?? defaultRates[t] ?? 1.0;
    return baseToUsd > 0.0 ? targetToUsd / baseToUsd : 1.0;
  }

  List<RatePoint> getHistoricalPoints(
    String baseCode,
    String targetCode,
    TimeScale scale,
  ) {
    final currentLive = getRate(baseCode, targetCode);
    if (scale == TimeScale.oneDay) {
      return HourlyRateLedger.buildHourlyPoints(
        baseCode,
        targetCode,
        currentLive,
        ledger: _dailyLedger,
      );
    }

    final cacheKey =
        '${baseCode.toUpperCase()}_${targetCode.toUpperCase()}_${scale.code}';
    final cached = _historicalCache[cacheKey];
    if (cached != null) return cached;

    final ledgerPoints = _dailyLedger.buildRatePoints(
      baseCode,
      targetCode,
      scale,
      currentLive,
    );
    if (ledgerPoints.length >= 2) {
      _historicalCache[cacheKey] = ledgerPoints;
      return ledgerPoints;
    }

    final points = _generateStochasticPoints(baseCode, targetCode, scale);
    _historicalCache[cacheKey] = points;
    return points;
  }

  Future<List<RatePoint>> fetchHistoricalPoints(
    String baseCode,
    String targetCode,
    TimeScale scale,
  ) async {
    final b = baseCode.toUpperCase();
    final t = targetCode.toUpperCase();

    await refreshRatesIfNeeded(force: false);

    if (scale == TimeScale.oneDay) {
      final pairKey = '${b}_$t';
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cachedIntraday = _intradayCache[pairKey];
      if (cachedIntraday != null && (nowMs - cachedIntraday.fetchedMs) < 60000) {
        return cachedIntraday.points;
      }

      if (b != t) {
        try {
          final symbol = b == 'USD' ? '$t=X' : '$b$t=X';
          final resp = await _apiClient.fetchYahooHourlyChart(symbol);
          if (resp != null && resp.samples.length >= 6) {
            final latestTsMs = resp.samples.last.timestampSec * 1000;
            final cutoff = latestTsMs - 24 * 3600 * 1000;
            var window = resp.samples
                .where((s) => s.timestampSec * 1000 >= cutoff)
                .toList();
            if (window.length < 6) {
              window = resp.samples.sublist(
                math.max(0, resp.samples.length - 24),
              );
            }

            final dateFmt = DateFormat('MM/dd');
            final timeFmt = DateFormat('HH:mm');
            final liveMarket = resp.regularMarketPrice;

            final livePoints = List<RatePoint>.generate(window.length, (idx) {
              final sample = window[idx];
              final tsMs = sample.timestampSec * 1000;
              final dt = DateTime.fromMillisecondsSinceEpoch(tsMs);
              final finalRate = (idx == window.length - 1 &&
                      liveMarket != null &&
                      liveMarket > 0)
                  ? liveMarket
                  : sample.close;
              return RatePoint(
                timestampMs: tsMs,
                dateLabel: dateFmt.format(dt),
                timeLabel: timeFmt.format(dt),
                rate: finalRate,
              );
            });

            if (liveMarket != null && liveMarket > 0) {
              if (b == 'USD') {
                _cachedRates[t] = liveMarket;
              } else if (t == 'USD') {
                _cachedRates[b] = 1.0 / liveMarket;
              }
              lastUpdatedTimeString =
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
              dataProviderName = 'Live Intraday FX';
              connectionStatus = ApiConnectionStatus.live;
            }
            _intradayCache[pairKey] = (fetchedMs: nowMs, points: livePoints);
            return livePoints;
          }
        } catch (_) {
          // Fall back to calibrated hourly ledger below
        }
      }
      return HourlyRateLedger.buildHourlyPoints(
        b,
        t,
        getRate(b, t),
        ledger: _dailyLedger,
      );
    }

    final cacheKey = '${b}_${t}_${scale.code}';
    const nonEcb = {'TWD', 'VND', 'AED'};
    if (!nonEcb.contains(b) && !nonEcb.contains(t)) {
      try {
        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd');
        final endDate = dateFormat.format(now);
        final DateTime startDt;
        switch (scale) {
          case TimeScale.oneWeek:
            startDt = now.subtract(const Duration(days: 8));
            break;
          case TimeScale.oneMonth:
            startDt = now.subtract(const Duration(days: 35));
            break;
          case TimeScale.oneYear:
            startDt = DateTime(now.year - 1, now.month, now.day);
            break;
          case TimeScale.fiveYears:
            startDt = DateTime(now.year - 5, now.month, now.day);
            break;
          case TimeScale.tenYears:
          case TimeScale.oneDay:
            startDt = DateTime(now.year - 10, now.month, now.day);
            break;
        }
        final startDate = dateFormat.format(startDt);
        final symbolsParam = b == 'USD' ? t : (t == 'USD' ? b : '$b,$t');

        final timeseries = await _apiClient.fetchFrankfurterTimeseries(
          startDate: startDate,
          endDate: endDate,
          symbols: symbolsParam,
          base: 'USD',
        );
        if (timeseries != null && timeseries.isNotEmpty) {
          _dailyLedger.updateFromTimeseries(timeseries);
          final currentLive = getRate(baseCode, targetCode);
          final updatedPoints =
              _dailyLedger.buildRatePoints(b, t, scale, currentLive);
          if (updatedPoints.length >= 2) {
            _historicalCache[cacheKey] = updatedPoints;
            return updatedPoints;
          }
        }
      } catch (_) {
        // Fallback to local ledger / stochastic
      }
    }

    return getHistoricalPoints(baseCode, targetCode, scale);
  }

  List<RatePoint> _generateStochasticPoints(
    String baseCode,
    String targetCode,
    TimeScale scale,
  ) {
    final currentRate = getRate(baseCode, targetCode);
    final now = DateTime.now().millisecondsSinceEpoch;
    final count = scale.pointsCount;

    final ratioStartBase = _getHistoricalRatioVsUsd(baseCode, scale);
    final ratioStartTarget = _getHistoricalRatioVsUsd(targetCode, scale);
    final targetStartRate = currentRate * (ratioStartTarget / ratioStartBase);

    final int timeStepMillis;
    switch (scale) {
      case TimeScale.oneDay:
        timeStepMillis = 3600 * 1000;
        break;
      case TimeScale.oneWeek:
      case TimeScale.oneMonth:
        timeStepMillis = 24 * 3600 * 1000;
        break;
      case TimeScale.oneYear:
        timeStepMillis = 7 * 24 * 3600 * 1000;
        break;
      case TimeScale.fiveYears:
      case TimeScale.tenYears:
        timeStepMillis = 30 * 24 * 3600 * 1000;
        break;
    }

    final totalDurationMillis = timeStepMillis * (count - 1);
    final startTime = now - totalDurationMillis;

    final pairSeed =
        baseCode.hashCode * 37 + targetCode.hashCode * 19 + scale.name.hashCode;
    final rng = math.Random(pairSeed);

    final double dailyVol;
    if ((baseCode == 'USD' && targetCode == 'HKD') ||
        (baseCode == 'HKD' && targetCode == 'USD')) {
      dailyVol = 0.0006;
    } else if (baseCode == 'TRY' || targetCode == 'TRY') {
      dailyVol = 0.018;
    } else if (scale == TimeScale.oneDay) {
      dailyVol = 0.0025;
    } else if (scale == TimeScale.oneWeek) {
      dailyVol = 0.0045;
    } else if (scale == TimeScale.oneMonth) {
      dailyVol = 0.0065;
    } else if (scale == TimeScale.oneYear) {
      dailyVol = 0.009;
    } else {
      dailyVol = 0.012;
    }

    final rawWalk = List<double>.filled(count, 0.0);
    var currentWalk = 0.0;
    for (var i = 1; i < count; i++) {
      final shock = (rng.nextDouble() * 2.0 - 1.0) * dailyVol;
      final cycle3d = math.sin(i * 1.95 + (pairSeed % 7)) * (dailyVol * 0.75);
      final cycle7d = math.cos(i * 0.85 + (pairSeed % 11)) * (dailyVol * 0.65);
      final cycle14d = math.sin(i * 0.42 + (pairSeed % 13)) * (dailyVol * 0.5);
      currentWalk += shock + (cycle3d + cycle7d + cycle14d) * 0.35;
      rawWalk[i] = currentWalk;
    }

    final targetDiff = currentRate - targetStartRate;
    final walkEnd = rawWalk[count - 1];

    final points = <RatePoint>[];
    for (var i = 0; i < count; i++) {
      final t = i / math.max(1, count - 1);
      final pointTime = startTime + i * timeStepMillis;
      final bridgedWalk = rawWalk[i] - (t * walkEnd);
      final trendComponent = targetStartRate + (t * targetDiff);
      final rawRate = trendComponent + (bridgedWalk * currentRate);
      final pointRate =
          i == count - 1 ? currentRate : math.max(0.000001, rawRate);

      final labels = RealDailyLedger.formatTimeLabels(pointTime, scale);
      points.add(
        RatePoint(
          timestampMs: pointTime,
          dateLabel: labels.$1,
          timeLabel: labels.$2,
          rate: pointRate,
        ),
      );
    }

    return points;
  }

  double _getHistoricalRatioVsUsd(String code, TimeScale scale) {
    final c = code.toUpperCase();
    if (c == 'USD') return 1.0;
    switch (scale) {
      case TimeScale.oneDay:
        return 1.0 + math.sin(c.hashCode * 0.5) * 0.003;
      case TimeScale.oneWeek:
        return 1.0 + math.cos(c.hashCode * 0.7) * 0.006;
      case TimeScale.oneMonth:
        final y1 = _historicalRatios1Y[c];
        return y1 != null ? 1.0 + (y1 - 1.0) * 0.12 : 1.0;
      case TimeScale.oneYear:
        return _historicalRatios1Y[c] ?? 0.98;
      case TimeScale.fiveYears:
        return _historicalRatios5Y[c] ?? 0.92;
      case TimeScale.tenYears:
        return _historicalRatios10Y[c] ?? 0.88;
    }
  }

  SinglePairStats getSinglePairStats(List<RatePoint> points) {
    if (points.isEmpty) return SinglePairStats.empty;
    final currentRate = points.last.rate;
    final initialRate = points.first.rate;
    final change = currentRate - initialRate;
    final changePercent =
        initialRate > 0 ? (change / initialRate) * 100.0 : 0.0;
    var minRate = points.first.rate;
    var maxRate = points.first.rate;
    var sum = 0.0;
    for (final p in points) {
      if (p.rate < minRate) minRate = p.rate;
      if (p.rate > maxRate) maxRate = p.rate;
      sum += p.rate;
    }
    return SinglePairStats(
      currentRate: currentRate,
      initialRate: initialRate,
      change: change,
      changePercent: changePercent,
      minRate: minRate,
      maxRate: maxRate,
      avgRate: sum / points.length,
    );
  }

  static const List<int> overlayColors = [
    0xFFFFB300,
    0xFF00BFA5,
    0xFFE040FB,
  ];

  Future<List<OverlayCurrencyData>> fetchOverlayData(
    String mainBaseCode,
    List<String> compareCodes,
    TimeScale scale,
  ) async {
    final trimmed = compareCodes.take(3).toList();
    final results = await Future.wait(
      trimmed.map((code) => fetchHistoricalPoints(mainBaseCode, code, scale)),
    );

    return List<OverlayCurrencyData>.generate(trimmed.length, (index) {
      return _buildOverlayEntry(
        code: trimmed[index],
        index: index,
        points: results[index],
      );
    });
  }

  List<OverlayCurrencyData> getOverlayData(
    String mainBaseCode,
    List<String> compareCodes,
    TimeScale scale,
  ) {
    final trimmed = compareCodes.take(3).toList();
    return List<OverlayCurrencyData>.generate(trimmed.length, (index) {
      final code = trimmed[index];
      final points = getHistoricalPoints(mainBaseCode, code, scale);
      return _buildOverlayEntry(code: code, index: index, points: points);
    });
  }

  OverlayCurrencyData _buildOverlayEntry({
    required String code,
    required int index,
    required List<RatePoint> points,
  }) {
    final currency = CurrencyCatalog.find(code);
    final initialRate = points.isNotEmpty ? points.first.rate : 1.0;
    final latestRate = points.isNotEmpty ? points.last.rate : 1.0;
    final changePercent = initialRate > 0
        ? ((latestRate - initialRate) / initialRate) * 100.0
        : 0.0;

    final normalizedPoints = points.map((p) {
      final normVal =
          initialRate > 0 ? ((p.rate - initialRate) / initialRate) * 100.0 : 0.0;
      return p.copyWith(rate: normVal);
    }).toList();

    var minRate = points.isNotEmpty ? points.first.rate : 0.0;
    var maxRate = points.isNotEmpty ? points.first.rate : 1.0;
    for (final p in points) {
      if (p.rate < minRate) minRate = p.rate;
      if (p.rate > maxRate) maxRate = p.rate;
    }

    final colorValue =
        index < overlayColors.length ? overlayColors[index] : 0xFF29B6F6;

    return OverlayCurrencyData(
      currency: currency,
      colorValue: colorValue,
      points: points,
      normalizedPoints: normalizedPoints,
      latestRate: latestRate,
      changePercent: changePercent,
      minRate: minRate,
      maxRate: maxRate,
    );
  }
}
