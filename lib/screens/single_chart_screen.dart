import 'package:flutter/material.dart';
import '../models/fx_models.dart';
import '../state/fx_controller.dart';
import '../utils/chart_export_helper.dart';
import '../utils/localization.dart';
import '../widgets/currency_picker_sheet.dart';
import '../widgets/single_line_chart.dart';

class SingleChartScreen extends StatelessWidget {
  const SingleChartScreen({super.key, required this.controller});

  final FxController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = controller.appLanguage;
    final base = controller.singleBase;
    final target = controller.singleTarget;
    final scale = controller.singleScale;
    final stats = controller.singleStats;
    final decimals = controller.getSingleDisplayDecimals();

    final isPositive = stats.changePercent >= 0;
    final trendColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = isPositive ? '+' : '';
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Web-style From / Swap / To Selector Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PairPickerButton(
                          label: Localization.fromLabel(lang),
                          flag: base.flag,
                          code: base.code,
                          name: base.getName(lang),
                          onTap: () async {
                            final picked = await showCurrencyPickerSheet(
                              context: context,
                              lang: lang,
                              title: Localization.baseCurrency(lang),
                            );
                            if (picked != null) {
                              controller.setSingleBase(picked);
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          onTap: controller.swapSingleCurrencies,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.swap_horiz,
                              color: scheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _PairPickerButton(
                          label: Localization.toLabel(lang),
                          flag: target.flag,
                          code: target.code,
                          name: target.getName(lang),
                          onTap: () async {
                            final picked = await showCurrencyPickerSheet(
                              context: context,
                              lang: lang,
                              title: Localization.targetCurrency(lang),
                            );
                            if (picked != null) {
                              controller.setSingleTarget(picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          Localization.midmarketRatesNote(lang),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Chart Card (Web Header + Time Scale Pills + Interactive Chart)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pair Title & Delta + Live Quote Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '${base.code} → ${target.code} ${Localization.chartTitleSuffix(lang)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: trendColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$sign${stats.changePercent.toStringAsFixed(2)}% (${scale.getLabel(lang)})',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: trendColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${base.getName(lang)} → ${target.getName(lang)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 1 BASE = X.XXXXX TARGET + Timestamp
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: controller.connectionStatus ==
                                  ApiConnectionStatus.live
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '1 ${base.code} = ${stats.currentRate.toStringAsFixed(decimals)} ${target.code}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        controller.lastUpdated,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Time Scale Segmented Pill Selector (1D, 1W, 1M, 1Y, 5Y, 10Y)
                  Container(
                    height: 38,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: TimeScale.values.map((s) {
                        final selected = s == scale;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => controller.setSingleScale(s),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? scheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                s.getLabel(lang),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: selected
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Interactive Line Chart
                  SingleLineChart(
                    points: controller.singlePoints,
                    targetCurrency: target,
                    lang: lang,
                    displayDecimals: decimals,
                    isIntraday: scale == TimeScale.oneDay,
                    isPositive: isPositive,
                    lineColor: scheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Statistics Metrics Row (High / Low / Average)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      title: Localization.statsHigh(lang),
                      value:
                          '${target.symbol}${stats.maxRate.toStringAsFixed(decimals)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      title: Localization.statsLow(lang),
                      value:
                          '${target.symbol}${stats.minRate.toStringAsFixed(decimals)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      title: Localization.statsAvg(lang),
                      value:
                          '${target.symbol}${stats.avgRate.toStringAsFixed(decimals)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Download JPG Button
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: controller.isExporting
                  ? null
                  : () async {
                      final path = await controller.exportSingleChartJpg(
                        isDarkTheme: isDark,
                      );
                      if (!context.mounted || path == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(Localization.exportSuccess(lang)),
                          action: SnackBarAction(
                            label: Localization.shareImage(lang),
                            onPressed: () =>
                                ChartExportHelper.shareExportedJpg(path),
                          ),
                        ),
                      );
                    },
              icon: controller.isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(
                controller.isExporting
                    ? Localization.exportingImage(lang)
                    : Localization.downloadJpg(lang),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PairPickerButton extends StatelessWidget {
  const _PairPickerButton({
    required this.label,
    required this.flag,
    required this.code,
    required this.name,
    required this.onTap,
  });

  final String label;
  final String flag;
  final String code;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$code · $name',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
