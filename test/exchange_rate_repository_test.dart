import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:global_fx_tracker/data/fx_api_client.dart';
import 'package:global_fx_tracker/data/hourly_rate_ledger.dart';
import 'package:global_fx_tracker/data/real_daily_ledger.dart';
import 'package:global_fx_tracker/models/fx_models.dart';
import 'package:global_fx_tracker/repositories/exchange_rate_repository.dart';

void main() {
  group('FxApiClient & ExchangeRateRepository', () {
    test('parses live open.er-api.com rates and updates cross rates', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'open.er-api.com') {
          return http.Response(
            jsonEncode({
              'result': 'success',
              'base_code': 'USD',
              'time_last_update_unix': 1794528151,
              'rates': {'HKD': 7.85, 'JPY': 160.0, 'EUR': 0.90},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = ExchangeRateRepository(
        apiClient: FxApiClient(httpClient: mockClient),
      );
      final ok = await repo.refreshRates();

      expect(ok, isTrue);
      expect(repo.connectionStatus, ApiConnectionStatus.live);
      expect(repo.getRate('USD', 'HKD'), closeTo(7.85, 1e-6));
      expect(repo.getRate('EUR', 'JPY'), closeTo(160.0 / 0.90, 1e-6));
    });

    test('falls back to Frankfurter ECB when primary API fails', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'open.er-api.com') {
          return http.Response('Upstream error', 503);
        }
        if (request.url.host == 'api.frankfurter.dev') {
          return http.Response(
            jsonEncode({
              'base': 'USD',
              'date': '2026-11-12',
              'rates': {'HKD': 7.8448, 'JPY': 159.7},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = ExchangeRateRepository(
        apiClient: FxApiClient(httpClient: mockClient),
      );
      final ok = await repo.refreshRates();

      expect(ok, isTrue);
      expect(repo.connectionStatus, ApiConnectionStatus.live);
      expect(repo.dataProviderName, contains('ECB'));
      expect(repo.getRate('USD', 'HKD'), closeTo(7.8448, 1e-6));
    });

    test('switches to fallback status cleanly if all APIs fail', () async {
      final mockClient = MockClient((_) async => http.Response('Offline', 503));
      final repo = ExchangeRateRepository(
        apiClient: FxApiClient(httpClient: mockClient),
      );

      final ok = await repo.refreshRates();

      expect(ok, isFalse);
      expect(repo.connectionStatus, ApiConnectionStatus.fallback);
      expect(repo.getRate('USD', 'HKD'), closeTo(7.84444, 1e-5));
    });

    test('HourlyRateLedger USD/HKD 1D series preserves benchmark points', () {
      final points = HourlyRateLedger.buildHourlyPoints(
        'USD',
        'HKD',
        HourlyRateLedger.usdHkdRefLive,
        nowMillis: 1794511920000,
      );
      expect(points.length, 49);
      expect(points.first.rate, closeTo(7.84498, 1e-5));
      expect(points.last.rate, closeTo(7.84444, 1e-5));
    });

    test('RealDailyLedger loads JSON and builds overlay normalized points from 0%', () {
      final ledger = RealDailyLedger.instance;
      final loaded = ledger.loadFromJsonString(jsonEncode({
        '2026-11-01': {'HKD': 7.80, 'JPY': 155.0, 'EUR': 0.90},
        '2026-11-10': {'HKD': 7.84, 'JPY': 159.7, 'EUR': 0.91},
      }));
      expect(loaded, isTrue);

      final repo = ExchangeRateRepository(dailyLedger: ledger);
      final overlay = repo.getOverlayData('USD', ['HKD', 'JPY', 'EUR'], TimeScale.oneMonth);

      expect(overlay.length, 3);
      for (final item in overlay) {
        expect(item.normalizedPoints.first.rate, closeTo(0.0, 1e-6));
      }
    });
  });
}
