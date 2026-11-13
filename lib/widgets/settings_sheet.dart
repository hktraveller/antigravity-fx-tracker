import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../models/fx_models.dart';
import '../state/fx_controller.dart';
import '../utils/localization.dart';
import 'currency_picker_sheet.dart';

Future<void> showSettingsSheet({
  required BuildContext context,
  required FxController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SettingsSheetContent(controller: controller),
  );
}

class _SettingsSheetContent extends StatelessWidget {
  const _SettingsSheetContent({required this.controller});

  final FxController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final lang = controller.appLanguage;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.tune, color: scheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Localization.settingsTitle(lang),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _SectionHeader(
                  icon: Icons.language,
                  title: Localization.defaultLanguageSetting(lang),
                ),
                _SegmentedBar<AppLanguage>(
                  values: AppLanguage.values,
                  selected: lang,
                  labelBuilder: (l) => l.title,
                  onSelected: controller.setLanguage,
                ),
                const SizedBox(height: 18),

                _SectionHeader(
                  icon: Icons.palette_outlined,
                  title: Localization.appearanceThemeSetting(lang),
                ),
                _SegmentedBar<AppThemeMode>(
                  values: AppThemeMode.values,
                  selected: controller.themeMode,
                  labelBuilder: (m) {
                    switch (m) {
                      case AppThemeMode.system:
                        return Localization.themeSystem(lang);
                      case AppThemeMode.light:
                        return Localization.themeLight(lang);
                      case AppThemeMode.dark:
                        return Localization.themeDark(lang);
                    }
                  },
                  onSelected: controller.setThemeMode,
                ),
                const SizedBox(height: 18),

                _SectionHeader(
                  icon: Icons.currency_exchange,
                  title: Localization.tabSingleChart(lang),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _DefaultCurrencyTile(
                        label: Localization.defaultBaseCurrencySetting(lang),
                        currency: controller.defaultBaseCurrency,
                        onTap: () async {
                          final picked = await showCurrencyPickerSheet(
                            context: context,
                            lang: lang,
                            title: Localization.defaultBaseCurrencySetting(lang),
                          );
                          if (picked != null) {
                            await controller.setDefaultBaseCurrency(picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DefaultCurrencyTile(
                        label: Localization.defaultTargetCurrencySetting(lang),
                        currency: controller.defaultTargetCurrency,
                        onTap: () async {
                          final picked = await showCurrencyPickerSheet(
                            context: context,
                            lang: lang,
                            title: Localization.defaultTargetCurrencySetting(lang),
                          );
                          if (picked != null) {
                            await controller.setDefaultTargetCurrency(picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  Localization.defaultTimeScaleSetting(lang),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                _SegmentedBar<TimeScale>(
                  values: TimeScale.values,
                  selected: controller.defaultTimeScale,
                  labelBuilder: (s) => s.getLabel(lang),
                  onSelected: controller.setDefaultTimeScale,
                ),
                const SizedBox(height: 18),

                _SectionHeader(
                  icon: Icons.precision_manufacturing_outlined,
                  title: Localization.highPrecisionMode(lang),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          Localization.highPrecisionMode(lang),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(Localization.highPrecisionDesc(lang)),
                        value: controller.highPrecisionDecimals,
                        onChanged: controller.setHighPrecisionDecimals,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(
                          Localization.autoRefreshOnStart(lang),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(Localization.autoRefreshDesc(lang)),
                        value: controller.autoRefreshOnLaunch,
                        onChanged: controller.setAutoRefreshOnLaunch,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                _SectionHeader(
                  icon: Icons.sync,
                  title: Localization.storageAndCache(lang),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await controller.clearCacheAndSync();
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: Text(
                          Localization.clearCacheAndSync(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                        ),
                        onPressed: () async {
                          await controller.resetAllSettings();
                        },
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: Text(
                          Localization.resetAllSettings(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: scheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Localization.appTitle(lang)} v1.2 (Flutter)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${Localization.appVersionInfo(lang)} • ${controller.connectionStatus == ApiConnectionStatus.live ? Localization.liveIndicator(lang) : Localization.offlineFallbackIndicator(lang)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedBar<T> extends StatelessWidget {
  const _SegmentedBar({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: values.map((v) {
          final isSel = v == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(v),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  labelBuilder(v),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DefaultCurrencyTile extends StatelessWidget {
  const _DefaultCurrencyTile({
    required this.label,
    required this.currency,
    required this.onTap,
  });

  final String label;
  final Currency currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(currency.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  currency.code,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
