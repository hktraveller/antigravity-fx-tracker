enum AppLanguage {
  english('en', 'English'),
  traditionalChinese('zh-TW', '繁體中文'),
  simplifiedChinese('zh-CN', '简体中文');

  const AppLanguage(this.code, this.title);

  final String code;
  final String title;

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.english;
    return AppLanguage.values.firstWhere(
      (e) => e.code.toLowerCase() == code.toLowerCase(),
      orElse: () => AppLanguage.english,
    );
  }
}

enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.code);

  final String code;

  static AppThemeMode fromCode(String? code) {
    if (code == null) return AppThemeMode.system;
    return AppThemeMode.values.firstWhere(
      (e) => e.code.toLowerCase() == code.toLowerCase(),
      orElse: () => AppThemeMode.system,
    );
  }
}

class Currency {
  const Currency({
    required this.code,
    required this.flag,
    required this.symbol,
    required this.nameZhTw,
    required this.nameZhCn,
    required this.nameEn,
    this.defaultDecimals = 4,
  });

  final String code;
  final String flag;
  final String symbol;
  final String nameZhTw;
  final String nameZhCn;
  final String nameEn;
  final int defaultDecimals;

  String getName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return nameZhTw;
      case AppLanguage.simplifiedChinese:
        return nameZhCn;
      case AppLanguage.english:
        return nameEn;
    }
  }

  String displayNameWithCode(AppLanguage lang) {
    return '$flag $code - ${getName(lang)}';
  }
}
