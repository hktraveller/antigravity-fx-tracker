import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../models/fx_models.dart';
import '../state/fx_controller.dart';
import '../utils/localization.dart';
import '../widgets/settings_sheet.dart';
import 'conversion_table_screen.dart';
import 'overlay_chart_screen.dart';
import 'single_chart_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.controller});

  final FxController controller;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshOnUse(force: true);
    }
  }

  void _showAboutDialog(BuildContext context, AppLanguage lang) {
    final String body;
    final String currencies;
    switch (lang) {
      case AppLanguage.traditionalChinese:
        body =
            '全球匯率通提供即時外匯行情、多維度交互式走勢圖（1天/1週/1個月/1年/5年/10年）、三幣疊加對比走勢、專業高品質 JPG 圖表匯出與分享，以及支援多達 10 種貨幣的互動即時速算表。';
        currencies =
            '支援貨幣：HKD, USD, JPY, EUR, GBP, CNY, SGD, THB, TWD, TRY, NZD, AUD, CAD, VND, KRW 等全球主要貨幣。';
        break;
      case AppLanguage.simplifiedChinese:
        body =
            '全球汇率通提供实时外汇行情、多维度交互式走势图（1天/1周/1个月/1年/5年/10年）、三币叠加对比走势、专业高品质 JPG 图表导出与分享，以及支持多达 10 种货币的互动实时速算表。';
        currencies =
            '支持货币：HKD, USD, JPY, EUR, GBP, CNY, SGD, THB, TWD, TRY, NZD, AUD, CAD, VND, KRW 等全球主要货币。';
        break;
      case AppLanguage.english:
        body =
            'Global FX Tracker provides real-time currency rates, multi-scale interactive line charts (1D, 1W, 1M, 1Y, 5Y, 10Y), 3-FX overlay comparisons, high-resolution JPG chart export & sharing, and an interactive 10-currency conversion table.';
        currencies =
            'Supported Currencies: HKD, USD, JPY, EUR, GBP, CNY, SGD, THB, TWD, TRY, NZD, AUD, CAD, VND, KRW, and major world currencies.';
        break;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Localization.appTitle(lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: 10),
            Text(
              currencies,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Localization.close(lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final lang = ctrl.appLanguage;
        final scheme = Theme.of(context).colorScheme;
        final isLive = ctrl.connectionStatus == ApiConnectionStatus.live;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      Localization.appTitle(lang),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${Localization.lastUpdated(lang)}: ${ctrl.lastUpdated} (${ctrl.dataProviderName})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: Localization.refresh(lang),
                onPressed: ctrl.isRefreshing
                    ? null
                    : () async {
                        final ok = await ctrl.refreshAllData();
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${Localization.offlineFallbackIndicator(lang)}: ${ctrl.lastConnectionError ?? ""}',
                              ),
                            ),
                          );
                        }
                      },
                icon: ctrl.isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
              PopupMenuButton<AppLanguage>(
                tooltip: Localization.changeLanguage(lang),
                icon: const Icon(Icons.language),
                onSelected: ctrl.setLanguage,
                itemBuilder: (ctx) => AppLanguage.values
                    .map(
                      (l) => PopupMenuItem<AppLanguage>(
                        value: l,
                        child: Row(
                          children: [
                            Text(
                              l.title,
                              style: TextStyle(
                                fontWeight: l == lang
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: l == lang ? scheme.primary : null,
                              ),
                            ),
                            if (l == lang) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check, size: 16, color: scheme.primary),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              IconButton(
                tooltip: Localization.settingsTitle(lang),
                icon: const Icon(Icons.settings_outlined),
                onPressed: () =>
                    showSettingsSheet(context: context, controller: ctrl),
              ),
              IconButton(
                tooltip: 'About',
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showAboutDialog(context, lang),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedTab,
            children: [
              SingleChartScreen(controller: ctrl),
              OverlayChartScreen(controller: ctrl),
              ConversionTableScreen(controller: ctrl),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (idx) {
              setState(() => _selectedTab = idx);
              ctrl.refreshOnUse(force: false);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.show_chart),
                label: Localization.tabSingleChart(lang),
              ),
              NavigationDestination(
                icon: const Icon(Icons.stacked_line_chart),
                label: Localization.tabOverlayChart(lang),
              ),
              NavigationDestination(
                icon: const Icon(Icons.calculate_outlined),
                label: Localization.tabConversionTable(lang),
              ),
            ],
          ),
        );
      },
    );
  }
}
