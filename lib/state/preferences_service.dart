import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';
import '../models/fx_models.dart';

class PreferencesService {
  static const _kLanguage = 'default_language';
  static const _kThemeMode = 'theme_mode';
  static const _kBaseCurrency = 'default_base';
  static const _kTargetCurrency = 'default_target';
  static const _kTimeScale = 'default_scale';
  static const _kHighPrecision = 'high_precision';
  static const _kAutoRefresh = 'auto_refresh';

  SharedPreferences? _prefs;

  AppLanguage defaultLanguage = AppLanguage.traditionalChinese;
  AppThemeMode themeMode = AppThemeMode.system;
  String defaultBaseCurrency = 'USD';
  String defaultTargetCurrency = 'HKD';
  TimeScale defaultTimeScale = TimeScale.oneDay;
  bool highPrecisionDecimals = false;
  bool autoRefreshOnLaunch = true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    defaultLanguage =
        AppLanguage.fromCode(_prefs?.getString(_kLanguage) ?? 'zh-TW');
    themeMode = AppThemeMode.fromCode(_prefs?.getString(_kThemeMode));
    defaultBaseCurrency =
        (_prefs?.getString(_kBaseCurrency) ?? 'USD').toUpperCase();
    defaultTargetCurrency =
        (_prefs?.getString(_kTargetCurrency) ?? 'HKD').toUpperCase();
    defaultTimeScale =
        TimeScale.fromCode(_prefs?.getString(_kTimeScale) ?? '1D');
    highPrecisionDecimals = _prefs?.getBool(_kHighPrecision) ?? false;
    autoRefreshOnLaunch = _prefs?.getBool(_kAutoRefresh) ?? true;
  }

  Future<void> setLanguage(AppLanguage lang) async {
    defaultLanguage = lang;
    await _prefs?.setString(_kLanguage, lang.code);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode = mode;
    await _prefs?.setString(_kThemeMode, mode.code);
  }

  Future<void> setDefaultBase(String code) async {
    defaultBaseCurrency = code.toUpperCase();
    await _prefs?.setString(_kBaseCurrency, defaultBaseCurrency);
  }

  Future<void> setDefaultTarget(String code) async {
    defaultTargetCurrency = code.toUpperCase();
    await _prefs?.setString(_kTargetCurrency, defaultTargetCurrency);
  }

  Future<void> setDefaultScale(TimeScale scale) async {
    defaultTimeScale = scale;
    await _prefs?.setString(_kTimeScale, scale.code);
  }

  Future<void> setHighPrecision(bool enabled) async {
    highPrecisionDecimals = enabled;
    await _prefs?.setBool(_kHighPrecision, enabled);
  }

  Future<void> setAutoRefresh(bool enabled) async {
    autoRefreshOnLaunch = enabled;
    await _prefs?.setBool(_kAutoRefresh, enabled);
  }

  Future<void> resetToDefaults() async {
    defaultLanguage = AppLanguage.traditionalChinese;
    themeMode = AppThemeMode.system;
    defaultBaseCurrency = 'USD';
    defaultTargetCurrency = 'HKD';
    defaultTimeScale = TimeScale.oneDay;
    highPrecisionDecimals = false;
    autoRefreshOnLaunch = true;
    await _prefs?.clear();
  }
}
