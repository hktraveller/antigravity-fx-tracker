import '../models/currency.dart';

class CurrencyCatalog {
  CurrencyCatalog._();

  static const List<Currency> allCurrencies = [
    Currency(code: 'HKD', flag: '🇭🇰', symbol: 'HK\$', nameZhTw: '港幣', nameZhCn: '港币', nameEn: 'Hong Kong Dollar', defaultDecimals: 4),
    Currency(code: 'USD', flag: '🇺🇸', symbol: '\$', nameZhTw: '美元', nameZhCn: '美元', nameEn: 'US Dollar', defaultDecimals: 4),
    Currency(code: 'JPY', flag: '🇯🇵', symbol: '¥', nameZhTw: '日圓', nameZhCn: '日元', nameEn: 'Japanese Yen', defaultDecimals: 2),
    Currency(code: 'EUR', flag: '🇪🇺', symbol: '€', nameZhTw: '歐元', nameZhCn: '欧元', nameEn: 'Euro', defaultDecimals: 4),
    Currency(code: 'GBP', flag: '🇬🇧', symbol: '£', nameZhTw: '英鎊', nameZhCn: '英镑', nameEn: 'British Pound', defaultDecimals: 4),
    Currency(code: 'CNY', flag: '🇨🇳', symbol: '¥', nameZhTw: '人民幣', nameZhCn: '人民币', nameEn: 'Chinese Yuan', defaultDecimals: 4),
    Currency(code: 'SGD', flag: '🇸🇬', symbol: 'S\$', nameZhTw: '新加坡幣', nameZhCn: '新加坡元', nameEn: 'Singapore Dollar', defaultDecimals: 4),
    Currency(code: 'THB', flag: '🇹🇭', symbol: '฿', nameZhTw: '泰銖', nameZhCn: '泰铢', nameEn: 'Thai Baht', defaultDecimals: 3),
    Currency(code: 'TWD', flag: '🇹🇼', symbol: 'NT\$', nameZhTw: '新台幣', nameZhCn: '新台币', nameEn: 'New Taiwan Dollar', defaultDecimals: 2),
    Currency(code: 'TRY', flag: '🇹🇷', symbol: '₺', nameZhTw: '土耳其里拉', nameZhCn: '土耳其里拉', nameEn: 'Turkish Lira', defaultDecimals: 2),
    Currency(code: 'NZD', flag: '🇳🇿', symbol: 'NZ\$', nameZhTw: '紐西蘭元', nameZhCn: '新西兰元', nameEn: 'New Zealand Dollar', defaultDecimals: 4),
    Currency(code: 'AUD', flag: '🇦🇺', symbol: 'A\$', nameZhTw: '澳元', nameZhCn: '澳大利亚元', nameEn: 'Australian Dollar', defaultDecimals: 4),
    Currency(code: 'CAD', flag: '🇨🇦', symbol: 'C\$', nameZhTw: '加拿大元', nameZhCn: '加拿大元', nameEn: 'Canadian Dollar', defaultDecimals: 4),
    Currency(code: 'VND', flag: '🇻🇳', symbol: '₫', nameZhTw: '越南盾', nameZhCn: '越南盾', nameEn: 'Vietnamese Dong', defaultDecimals: 0),
    Currency(code: 'KRW', flag: '🇰🇷', symbol: '₩', nameZhTw: '韓元', nameZhCn: '韩元', nameEn: 'South Korean Won', defaultDecimals: 1),
    Currency(code: 'CHF', flag: '🇨🇭', symbol: 'CHF', nameZhTw: '瑞士法郎', nameZhCn: '瑞士法郎', nameEn: 'Swiss Franc', defaultDecimals: 4),
    Currency(code: 'MYR', flag: '🇲🇾', symbol: 'RM', nameZhTw: '馬來西亞令吉', nameZhCn: '马来西亚林吉特', nameEn: 'Malaysian Ringgit', defaultDecimals: 4),
    Currency(code: 'INR', flag: '🇮🇳', symbol: '₹', nameZhTw: '印度盧比', nameZhCn: '印度卢比', nameEn: 'Indian Rupee', defaultDecimals: 2),
    Currency(code: 'PHP', flag: '🇵🇭', symbol: '₱', nameZhTw: '菲律賓披索', nameZhCn: '菲律宾比索', nameEn: 'Philippine Peso', defaultDecimals: 2),
    Currency(code: 'IDR', flag: '🇮🇩', symbol: 'Rp', nameZhTw: '印尼盾', nameZhCn: '印尼盾', nameEn: 'Indonesian Rupiah', defaultDecimals: 0),
    Currency(code: 'AED', flag: '🇦🇪', symbol: 'AED', nameZhTw: '阿聯酋迪拉姆', nameZhCn: '阿联酋迪拉姆', nameEn: 'UAE Dirham', defaultDecimals: 4),
    Currency(code: 'SEK', flag: '🇸🇪', symbol: 'kr', nameZhTw: '瑞典克朗', nameZhCn: '瑞典克朗', nameEn: 'Swedish Krona', defaultDecimals: 3),
    Currency(code: 'BRL', flag: '🇧🇷', symbol: 'R\$', nameZhTw: '巴西雷亞爾', nameZhCn: '巴西雷亚尔', nameEn: 'Brazilian Real', defaultDecimals: 2),
  ];

  static final Map<String, Currency> mapByCode = {
    for (final c in allCurrencies) c.code: c,
  };

  static Currency find(String code) {
    final upper = code.toUpperCase();
    return mapByCode[upper] ??
        Currency(
          code: upper,
          flag: '🌐',
          symbol: '\$',
          nameZhTw: upper,
          nameZhCn: upper,
          nameEn: upper,
        );
  }

  static const List<String> defaultConversionSelection = [
    'USD',
    'HKD',
    'JPY',
    'EUR',
    'GBP',
    'CNY',
    'TWD',
    'SGD',
    'KRW',
    'CAD',
  ];
}
