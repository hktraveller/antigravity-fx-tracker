import 'package:flutter/foundation.dart';
import '../data/currency_catalog.dart';
import '../models/currency.dart';
import '../models/fx_models.dart';
import '../repositories/exchange_rate_repository.dart';
import '../utils/chart_export_helper.dart';
import 'preferences_service.dart';

class FxController extends ChangeNotifier {
  FxController({
    ExchangeRateRepository? repository,
    PreferencesService? preferences,
  })  : _repository = repository ?? ExchangeRateRepository(),
        _prefs = preferences ?? PreferencesService();

  final ExchangeRateRepository _repository;
  final PreferencesService _prefs;

  AppLanguage appLanguage = AppLanguage.traditionalChinese;
  AppThemeMode themeMode = AppThemeMode.system;
  bool highPrecisionDecimals = false;
  bool autoRefreshOnLaunch = true;
  Currency defaultBaseCurrency = CurrencyCatalog.find('USD');
  Currency defaultTargetCurrency = CurrencyCatalog.find('HKD');
  TimeScale defaultTimeScale = TimeScale.oneDay;

  // Single Chart State
  Currency singleBase = CurrencyCatalog.find('USD');
  Currency singleTarget = CurrencyCatalog.find('HKD');
  TimeScale singleScale = TimeScale.oneDay;
  List<RatePoint> singlePoints = const [];
  SinglePairStats singleStats = SinglePairStats.empty;

  // Overlay Chart State
  Currency overlayMain = CurrencyCatalog.find('USD');
  List<Currency> overlayCompare = [
    CurrencyCatalog.find('HKD'),
    CurrencyCatalog.find('EUR'),
    CurrencyCatalog.find('JPY'),
  ];
  TimeScale overlayScale = TimeScale.oneDay;
  bool isNormalizedView = true;
  List<OverlayCurrencyData> overlayData = const [];

  // Conversion Table State
  List<Currency> tableCurrencies = CurrencyCatalog.defaultConversionSelection
      .map(CurrencyCatalog.find)
      .toList();
  String activeCurrencyCode = 'USD';
  double activeAmount = 100.0;
  String inputDisplayString = '100';
  int ratesVersion = 0;

  // Network & Export State
  bool isRefreshing = false;
  bool isExporting = false;
  String lastUpdated = '';
  String dataProviderName = '';
  ApiConnectionStatus connectionStatus = ApiConnectionStatus.connecting;
  String? lastConnectionError;

  Future<void> initialize() async {
    await _prefs.init();
    await _repository.init();

    appLanguage = _prefs.defaultLanguage;
    themeMode = _prefs.themeMode;
    highPrecisionDecimals = _prefs.highPrecisionDecimals;
    autoRefreshOnLaunch = _prefs.autoRefreshOnLaunch;
    defaultBaseCurrency = CurrencyCatalog.find(_prefs.defaultBaseCurrency);
    defaultTargetCurrency = CurrencyCatalog.find(_prefs.defaultTargetCurrency);
    defaultTimeScale = _prefs.defaultTimeScale;

    singleBase = defaultBaseCurrency;
    singleTarget = defaultTargetCurrency;
    singleScale = defaultTimeScale;
    overlayMain = defaultBaseCurrency;
    overlayScale = defaultTimeScale;
    activeCurrencyCode = defaultBaseCurrency.code;

    lastUpdated = _repository.lastUpdatedTimeString;
    dataProviderName = _repository.dataProviderName;
    connectionStatus = _repository.connectionStatus;

    _recomputeSingleChart();
    _recomputeOverlayChart();
    notifyListeners();

    if (autoRefreshOnLaunch) {
      await refreshAllData();
    }
  }

  void _syncRepoMetadata() {
    lastUpdated = _repository.lastUpdatedTimeString;
    dataProviderName = _repository.dataProviderName;
    connectionStatus = _repository.connectionStatus;
    lastConnectionError = _repository.lastConnectionError;
  }

  Future<void> refreshOnUse({bool force = false}) async {
    await _repository.refreshRatesIfNeeded(force: force);
    _syncRepoMetadata();
    _recomputeSingleChart();
    _recomputeOverlayChart();
    ratesVersion++;
    notifyListeners();
  }

  Future<bool> refreshAllData() async {
    isRefreshing = true;
    notifyListeners();

    final ok = await _repository.refreshRates();
    _syncRepoMetadata();
    isRefreshing = false;

    _recomputeSingleChart();
    _recomputeOverlayChart();
    ratesVersion++;
    notifyListeners();
    return ok;
  }

  // Settings Actions
  Future<void> setLanguage(AppLanguage lang) async {
    appLanguage = lang;
    await _prefs.setLanguage(lang);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode = mode;
    await _prefs.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setDefaultBaseCurrency(Currency currency) async {
    defaultBaseCurrency = currency;
    await _prefs.setDefaultBase(currency.code);
    setSingleBase(currency);
  }

  Future<void> setDefaultTargetCurrency(Currency currency) async {
    defaultTargetCurrency = currency;
    await _prefs.setDefaultTarget(currency.code);
    setSingleTarget(currency);
  }

  Future<void> setDefaultTimeScale(TimeScale scale) async {
    defaultTimeScale = scale;
    await _prefs.setDefaultScale(scale);
    setSingleScale(scale);
  }

  Future<void> setHighPrecisionDecimals(bool enabled) async {
    highPrecisionDecimals = enabled;
    await _prefs.setHighPrecision(enabled);
    notifyListeners();
  }

  Future<void> setAutoRefreshOnLaunch(bool enabled) async {
    autoRefreshOnLaunch = enabled;
    await _prefs.setAutoRefresh(enabled);
    notifyListeners();
  }

  Future<void> clearCacheAndSync() async {
    _repository.clearHistoricalCache();
    await refreshAllData();
  }

  Future<void> resetAllSettings() async {
    await _prefs.resetToDefaults();
    appLanguage = _prefs.defaultLanguage;
    themeMode = _prefs.themeMode;
    highPrecisionDecimals = _prefs.highPrecisionDecimals;
    autoRefreshOnLaunch = _prefs.autoRefreshOnLaunch;
    defaultBaseCurrency = CurrencyCatalog.find(_prefs.defaultBaseCurrency);
    defaultTargetCurrency = CurrencyCatalog.find(_prefs.defaultTargetCurrency);
    defaultTimeScale = _prefs.defaultTimeScale;

    singleBase = defaultBaseCurrency;
    singleTarget = defaultTargetCurrency;
    singleScale = defaultTimeScale;
    _recomputeSingleChart();
    _recomputeOverlayChart();
    notifyListeners();
  }

  // Single Chart Actions
  void setSingleBase(Currency currency) {
    singleBase = currency;
    _recomputeSingleChart();
  }

  void setSingleTarget(Currency currency) {
    singleTarget = currency;
    _recomputeSingleChart();
  }

  void swapSingleCurrencies() {
    final prevBase = singleBase;
    singleBase = singleTarget;
    singleTarget = prevBase;
    _recomputeSingleChart();
  }

  void setSingleScale(TimeScale scale) {
    singleScale = scale;
    _recomputeSingleChart();
  }

  void _recomputeSingleChart() {
    final reqBase = singleBase.code;
    final reqTarget = singleTarget.code;
    final reqScale = singleScale;

    final cached = _repository.getHistoricalPoints(reqBase, reqTarget, reqScale);
    singlePoints = cached;
    singleStats = _repository.getSinglePairStats(cached);
    notifyListeners();

    _repository.fetchHistoricalPoints(reqBase, reqTarget, reqScale).then((real) {
      if (real.isNotEmpty &&
          singleBase.code == reqBase &&
          singleTarget.code == reqTarget &&
          singleScale == reqScale) {
        singlePoints = real;
        singleStats = _repository.getSinglePairStats(real);
        _syncRepoMetadata();
        ratesVersion++;
        notifyListeners();
      }
    });
  }

  // Overlay Chart Actions
  void setOverlayMain(Currency currency) {
    overlayMain = currency;
    _recomputeOverlayChart();
  }

  void setOverlayCompare(int index, Currency currency) {
    if (index >= 0 && index < overlayCompare.length) {
      overlayCompare = List<Currency>.from(overlayCompare)..[index] = currency;
      _recomputeOverlayChart();
    }
  }

  void setOverlayScale(TimeScale scale) {
    overlayScale = scale;
    _recomputeOverlayChart();
  }

  void toggleNormalizedView() {
    isNormalizedView = !isNormalizedView;
    notifyListeners();
  }

  void _recomputeOverlayChart() {
    final reqMain = overlayMain.code;
    final codes = overlayCompare.map((e) => e.code).toList();
    final reqScale = overlayScale;

    overlayData = _repository.getOverlayData(reqMain, codes, reqScale);
    notifyListeners();

    _repository.fetchOverlayData(reqMain, codes, reqScale).then((real) {
      final currentCodes = overlayCompare.map((e) => e.code).toList();
      if (real.isNotEmpty &&
          overlayMain.code == reqMain &&
          listEquals(currentCodes, codes) &&
          overlayScale == reqScale) {
        overlayData = real;
        _syncRepoMetadata();
        notifyListeners();
      }
    });
  }

  // Conversion Table Actions
  void updateConversionInput(String code, String input) {
    final sanitized = input.replaceAll(RegExp(r'[^0-9.]'), '');
    final firstDot = sanitized.indexOf('.');
    final cleaned = firstDot == -1
        ? sanitized
        : sanitized.substring(0, firstDot + 1) +
            sanitized.substring(firstDot + 1).replaceAll('.', '');

    activeCurrencyCode = code;
    activeAmount = double.tryParse(cleaned) ?? 0.0;
    inputDisplayString = cleaned;
    notifyListeners();
  }

  void addQuickAmount(double delta) {
    final newAmt = (activeAmount + delta).clamp(0.0, double.infinity);
    activeAmount = newAmt;
    inputDisplayString =
        newAmt % 1 == 0 ? newAmt.toInt().toString() : newAmt.toStringAsFixed(2);
    notifyListeners();
  }

  void clearConversionInput() {
    activeAmount = 0.0;
    inputDisplayString = '';
    notifyListeners();
  }

  void addTableCurrency(Currency currency) {
    if (tableCurrencies.length < 10 &&
        tableCurrencies.every((c) => c.code != currency.code)) {
      tableCurrencies = [...tableCurrencies, currency];
      notifyListeners();
    }
  }

  void removeTableCurrency(Currency currency) {
    if (tableCurrencies.length <= 2) return;
    tableCurrencies =
        tableCurrencies.where((c) => c.code != currency.code).toList();
    if (activeCurrencyCode == currency.code) {
      activeCurrencyCode = tableCurrencies.first.code;
    }
    notifyListeners();
  }

  void resetTableDefaults() {
    tableCurrencies = CurrencyCatalog.defaultConversionSelection
        .map(CurrencyCatalog.find)
        .toList();
    activeCurrencyCode = defaultBaseCurrency.code;
    activeAmount = 100.0;
    inputDisplayString = '100';
    notifyListeners();
  }

  double calculateConvertedAmount(String targetCode) {
    return activeAmount * _repository.getRate(activeCurrencyCode, targetCode);
  }

  double getDirectRate(String baseCode, String targetCode) {
    return _repository.getRate(baseCode, targetCode);
  }

  int getSingleDisplayDecimals() {
    if (highPrecisionDecimals) {
      final minHigh = singleStats.currentRate < 50.0 ? 5 : 4;
      return singleTarget.defaultDecimals > minHigh
          ? singleTarget.defaultDecimals
          : minHigh;
    }
    if (singleScale == TimeScale.oneDay &&
        singleStats.currentRate >= 0.1 &&
        singleStats.currentRate <= 25.0) {
      return singleTarget.defaultDecimals > 5
          ? singleTarget.defaultDecimals
          : 5;
    }
    return singleTarget.defaultDecimals;
  }

  Future<String?> exportSingleChartJpg({required bool isDarkTheme}) async {
    isExporting = true;
    notifyListeners();
    try {
      return await ChartExportHelper.exportSingleChartAsJpg(
        baseCurrency: singleBase,
        targetCurrency: singleTarget,
        scale: singleScale,
        points: singlePoints,
        stats: singleStats,
        lang: appLanguage,
        isDarkTheme: isDarkTheme,
        displayDecimals: getSingleDisplayDecimals(),
      );
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  Future<String?> exportOverlayChartJpg({required bool isDarkTheme}) async {
    isExporting = true;
    notifyListeners();
    try {
      return await ChartExportHelper.exportOverlayChartAsJpg(
        mainBase: overlayMain,
        scale: overlayScale,
        overlayData: overlayData,
        lang: appLanguage,
        isDarkTheme: isDarkTheme,
      );
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }
}
