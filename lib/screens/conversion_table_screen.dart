import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../state/fx_controller.dart';
import '../utils/localization.dart';
import '../widgets/currency_picker_sheet.dart';

class ConversionTableScreen extends StatefulWidget {
  const ConversionTableScreen({super.key, required this.controller});

  final FxController controller;

  @override
  State<ConversionTableScreen> createState() => _ConversionTableScreenState();
}

class _ConversionTableScreenState extends State<ConversionTableScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.controller.inputDisplayString;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatAmount(double value, int decimals) {
    final pattern = decimals <= 0
        ? '#,##0'
        : '#,##0.${'0' * decimals}';
    return NumberFormat(pattern, 'en_US').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = ctrl.appLanguage;

    if (_textController.text != ctrl.inputDisplayString && !_focusNode.hasFocus) {
      _textController.text = ctrl.inputDisplayString;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          // Compact Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${ctrl.tableCurrencies.length}/10',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  for (final delta in [100.0, 1000.0, 10000.0])
                    InkWell(
                      onTap: () {
                        ctrl.addQuickAmount(delta);
                        _textController.text = ctrl.inputDisplayString;
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${delta.toInt()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: () {
                      ctrl.clearConversionInput();
                      _textController.clear();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        Localization.clear(lang),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (ctrl.tableCurrencies.length < 10)
                    InkWell(
                      onTap: () async {
                        final existing =
                            ctrl.tableCurrencies.map((e) => e.code).toSet();
                        final picked = await showCurrencyPickerSheet(
                          context: context,
                          lang: lang,
                          title: Localization.addCurrency(lang),
                          filterOutCodes: existing,
                        );
                        if (picked != null) {
                          ctrl.addTableCurrency(picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 14, color: scheme.onPrimary),
                            const SizedBox(width: 3),
                            Text(
                              Localization.addCurrency(lang),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: Localization.resetDefaults(lang),
                    onPressed: () {
                      ctrl.resetTableDefaults();
                      _textController.text = ctrl.inputDisplayString;
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Multi-currency interactive conversion list
          Expanded(
            child: ListView.separated(
              itemCount: ctrl.tableCurrencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final currency = ctrl.tableCurrencies[idx];
                final isActive = currency.code == ctrl.activeCurrencyCode;
                final directRate =
                    ctrl.getDirectRate(ctrl.activeCurrencyCode, currency.code);
                final convertedVal =
                    ctrl.calculateConvertedAmount(currency.code);
                final formatted =
                    _formatAmount(convertedVal, currency.defaultDecimals);

                return InkWell(
                  onTap: isActive
                      ? null
                      : () {
                          final newDisplay = convertedVal % 1 == 0
                              ? convertedVal.toInt().toString()
                              : convertedVal
                                  .toStringAsFixed(currency.defaultDecimals);
                          ctrl.updateConversionInput(currency.code, newDisplay);
                          _textController.text = ctrl.inputDisplayString;
                          _focusNode.requestFocus();
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: isActive
                          ? scheme.primaryContainer.withValues(alpha: 0.25)
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isActive ? scheme.primary : scheme.outlineVariant,
                        width: isActive ? 1.8 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(currency.flag,
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currency.code,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? scheme.primary : null,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'EDITING',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: scheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                currency.getName(lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '1 ${ctrl.activeCurrencyCode} = ${directRate.toStringAsFixed(4)} ${currency.code}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: isActive
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _textController,
                                        focusNode: _focusNode,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          prefixText: '${currency.symbol} ',
                                          prefixStyle: TextStyle(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (v) =>
                                            ctrl.updateConversionInput(
                                                currency.code, v),
                                      ),
                                    ),
                                    if (ctrl.inputDisplayString.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          ctrl.clearConversionInput();
                                          _textController.clear();
                                        },
                                      ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${currency.symbol} $formatted',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 15),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: formatted),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${currency.code} $formatted ${Localization.copied(lang)}',
                                            ),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                    if (ctrl.tableCurrencies.length > 2)
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: scheme.error
                                              .withValues(alpha: 0.7),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            ctrl.removeTableCurrency(currency),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
