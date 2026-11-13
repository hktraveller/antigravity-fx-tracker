import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:global_fx_tracker/data/fx_api_client.dart';
import 'package:global_fx_tracker/main.dart';
import 'package:global_fx_tracker/repositories/exchange_rate_repository.dart';
import 'package:global_fx_tracker/state/fx_controller.dart';
import 'package:global_fx_tracker/state/preferences_service.dart';

void main() {
  testWidgets('App renders Pair Chart, Overlay, and Converter tabs',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final mockClient = MockClient((_) async => http.Response('{}', 404));
    final repo = ExchangeRateRepository(
      apiClient: FxApiClient(httpClient: mockClient),
    );
    final prefs = PreferencesService();
    final controller = FxController(repository: repo, preferences: prefs);
    await tester.runAsync(() => controller.initialize());

    await tester.pumpWidget(GlobalFxTrackerApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('USD → HKD'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('三幣疊加'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('HKD'), findsWidgets);

    await tester.tap(find.text('多幣速算表'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('EDITING'), findsOneWidget);
  });
}
