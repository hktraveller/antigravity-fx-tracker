import 'package:flutter/material.dart';
import '../models/fx_models.dart';
import '../repositories/exchange_rate_repository.dart';
import '../state/fx_controller.dart';
import '../utils/chart_export_helper.dart';
import '../utils/localization.dart';
import '../widgets/currency_picker_sheet.dart';
import '../widgets/overlay_line_chart.dart';

class OverlayChartScreen extends StatelessWidget {
  const OverlayChartScreen({super.key, required this.controller});

  final FxController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = controller.appLanguage;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Overlay Chart Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: OverlayLineChart(
                mainCurrency: controller.overlayMain,
                overlayData: controller.overlayData,
                isNormalizedView: controller.isNormalizedView,
                lang: lang,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Time Scale Segmented Pill Selector
          Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: TimeScale.values.map((s) {
                final selected = s == controller.overlayScale;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setOverlayScale(s),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? scheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        s.getLabel(lang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
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
          const SizedBox(height: 10),

          // 3. Normalized % vs Scaled Rates Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.isNormalizedView
                      ? Localization.viewModePercent(lang)
                      : Localization.viewModeRaw(lang),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: controller.isNormalizedView,
                  onChanged: (_) => controller.toggleNormalizedView(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. Main Base Currency Selector Card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Localization.mainCurrencyLabel(lang),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${controller.overlayMain.flag} ${controller.overlayMain.code} (${controller.overlayMain.getName(lang)})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      final picked = await showCurrencyPickerSheet(
                        context: context,
                        lang: lang,
                        title: Localization.mainCurrencyLabel(lang),
                      );
                      if (picked != null) {
                        controller.setOverlayMain(picked);
                      }
                    },
                    child: Text(
                      Localization.selectCurrency(lang),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 5. 3 Comparison Slots
          Row(
            children: List.generate(controller.overlayCompare.length, (index) {
              final cur = controller.overlayCompare[index];
              final dotColor = Color(
                index < ExchangeRateRepository.overlayColors.length
                    ? ExchangeRateRepository.overlayColors[index]
                    : 0xFF29B6F6,
              );
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 2 ? 0 : 4,
                  ),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showCurrencyPickerSheet(
                        context: context,
                        lang: lang,
                        title:
                            '${Localization.selectCurrency(lang)} (#${index + 1})',
                        filterOutCodes: {controller.overlayMain.code},
                      );
                      if (picked != null) {
                        controller.setOverlayCompare(index, picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${cur.flag} ${cur.code}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  cur.getName(lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // 6. Summary Cards
          ...controller.overlayData.map((item) {
            final isUp = item.changePercent >= 0;
            final sign = isUp ? '+' : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color(item.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.currency.flag,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '${controller.overlayMain.code} → ${item.currency.code}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.currency.symbol}${item.latestRate.toStringAsFixed(item.currency.defaultDecimals)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$sign${item.changePercent.toStringAsFixed(2)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isUp
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),

          // 7. Download JPG Button
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: controller.isExporting
                  ? null
                  : () async {
                      final path = await controller.exportOverlayChartJpg(
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
