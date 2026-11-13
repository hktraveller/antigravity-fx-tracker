import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveSpotResult {
  const LiveSpotResult({
    required this.rates,
    required this.providerName,
    required this.timestampUnixSec,
  });

  final Map<String, double> rates;
  final String providerName;
  final int? timestampUnixSec;
}

class YahooIntradayResult {
  const YahooIntradayResult({
    required this.samples,
    required this.regularMarketPrice,
  });

  final List<({int timestampSec, double close})> samples;
  final double? regularMarketPrice;
}

/// Network client for live FX spot quotes, ECB timeseries, and intraday Yahoo FX charts.
class FxApiClient {
  FxApiClient({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const Duration _spotTimeout = Duration(seconds: 12);
  static const Duration _historyTimeout = Duration(seconds: 12);
  static const Duration _intradayTimeout = Duration(seconds: 5);

  /// Primary live spot endpoint: open.er-api.com (160+ currencies, base USD).
  Future<LiveSpotResult?> fetchOpenErUsdRates() async {
    final uri = Uri.parse('https://open.er-api.com/v6/latest/USD');
    final resp = await _client.get(
      uri,
      headers: const {
        'User-Agent': 'GlobalFxTracker/1.2 (Flutter; Android)',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    ).timeout(_spotTimeout);

    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['result'] != 'success') return null;
    final rawRates = body['rates'];
    if (rawRates is! Map<String, dynamic> || rawRates.isEmpty) return null;

    final rates = <String, double>{'USD': 1.0};
    rawRates.forEach((k, v) {
      if (v is num) {
        rates[k.toUpperCase()] = v.toDouble();
      }
    });

    final unix = body['time_last_update_unix'];
    return LiveSpotResult(
      rates: rates,
      providerName: 'ExchangeRate-API (Live)',
      timestampUnixSec: unix is num ? unix.toInt() : null,
    );
  }

  /// Backup live spot endpoint: Frankfurter / ECB.
  Future<LiveSpotResult?> fetchFrankfurterLatest() async {
    final uri = Uri.parse('https://api.frankfurter.dev/v1/latest?base=USD');
    final resp = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    ).timeout(_historyTimeout);

    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final rawRates = body['rates'];
    if (rawRates is! Map<String, dynamic> || rawRates.isEmpty) return null;

    final rates = <String, double>{'USD': 1.0};
    rawRates.forEach((k, v) {
      if (v is num) {
        rates[k.toUpperCase()] = v.toDouble();
      }
    });

    return LiveSpotResult(
      rates: rates,
      providerName: 'European Central Bank (ECB Live)',
      timestampUnixSec: null,
    );
  }

  /// Historical daily timeseries from Frankfurter ECB API.
  Future<Map<String, Map<String, double>>?> fetchFrankfurterTimeseries({
    required String startDate,
    required String endDate,
    required String symbols,
    String base = 'USD',
  }) async {
    final uri = Uri.parse(
      'https://api.frankfurter.dev/v1/$startDate..$endDate',
    ).replace(queryParameters: {'base': base, 'symbols': symbols});

    final resp = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    ).timeout(_historyTimeout);

    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final rawRates = body['rates'];
    if (rawRates is! Map<String, dynamic> || rawRates.isEmpty) return null;

    final parsed = <String, Map<String, double>>{};
    rawRates.forEach((date, dayObj) {
      if (dayObj is Map<String, dynamic>) {
        final dayMap = <String, double>{};
        dayObj.forEach((cur, val) {
          if (val is num) {
            dayMap[cur.toUpperCase()] = val.toDouble();
          }
        });
        if (dayMap.isNotEmpty) {
          parsed[date] = dayMap;
        }
      }
    });

    return parsed.isEmpty ? null : parsed;
  }

  /// Intraday 1D hourly chart from Yahoo Finance (tries query1 then query2 on 429/error).
  Future<YahooIntradayResult?> fetchYahooHourlyChart(String symbol) async {
    const hosts = ['query1.finance.yahoo.com', 'query2.finance.yahoo.com'];
    for (final host in hosts) {
      try {
        final uri = Uri.parse(
          'https://$host/v8/finance/chart/${Uri.encodeComponent(symbol)}',
        ).replace(queryParameters: {'interval': '1h', 'range': '2d'});

        final resp = await _client.get(
          uri,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ).timeout(_intradayTimeout);

        if (resp.statusCode != 200) continue;
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final chart = body['chart'];
        if (chart is! Map<String, dynamic>) continue;
        final results = chart['result'];
        if (results is! List || results.isEmpty) continue;

        final first = results.first as Map<String, dynamic>;
        final meta = first['meta'] as Map<String, dynamic>?;
        final regularPrice = meta?['regularMarketPrice'];
        final timestamps = first['timestamp'] as List?;
        final indicators = first['indicators'] as Map<String, dynamic>?;
        final quoteList = indicators?['quote'] as List?;
        final closes = (quoteList != null && quoteList.isNotEmpty)
            ? (quoteList.first as Map<String, dynamic>)['close'] as List?
            : null;

        if (timestamps == null || closes == null) continue;

        final samples = <({int timestampSec, double close})>[];
        final len = mathMin(timestamps.length, closes.length);
        for (var i = 0; i < len; i++) {
          final ts = timestamps[i];
          final c = closes[i];
          if (ts is num && c is num && c > 0) {
            samples.add((timestampSec: ts.toInt(), close: c.toDouble()));
          }
        }

        if (samples.isEmpty) continue;
        return YahooIntradayResult(
          samples: samples,
          regularMarketPrice:
              regularPrice is num ? regularPrice.toDouble() : null,
        );
      } catch (_) {
        // Try next host or fall back to HourlyRateLedger
      }
    }
    return null;
  }

  static int mathMin(int a, int b) => a < b ? a : b;

  void dispose() {
    _client.close();
  }
}
