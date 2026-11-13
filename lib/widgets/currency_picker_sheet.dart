import 'package:flutter/material.dart';
import '../data/currency_catalog.dart';
import '../models/currency.dart';
import '../utils/localization.dart';

Future<Currency?> showCurrencyPickerSheet({
  required BuildContext context,
  required AppLanguage lang,
  required String title,
  Set<String> filterOutCodes = const {},
}) {
  return showModalBottomSheet<Currency>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CurrencyPickerContent(
      lang: lang,
      title: title,
      filterOutCodes: filterOutCodes,
    ),
  );
}

class _CurrencyPickerContent extends StatefulWidget {
  const _CurrencyPickerContent({
    required this.lang,
    required this.title,
    required this.filterOutCodes,
  });

  final AppLanguage lang;
  final String title;
  final Set<String> filterOutCodes;

  @override
  State<_CurrencyPickerContent> createState() => _CurrencyPickerContentState();
}

class _CurrencyPickerContentState extends State<_CurrencyPickerContent> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final filtered = CurrencyCatalog.allCurrencies.where((c) {
      if (widget.filterOutCodes.contains(c.code)) return false;
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          c.nameEn.toLowerCase().contains(q) ||
          c.nameZhTw.toLowerCase().contains(q) ||
          c.nameZhCn.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SizedBox(
          height: 480,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: Localization.searchCurrency(widget.lang),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return ListTile(
                      leading: Text(item.flag, style: const TextStyle(fontSize: 28)),
                      title: Row(
                        children: [
                          Text(
                            item.code,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.symbol,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(item.getName(widget.lang)),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
