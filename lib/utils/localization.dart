import '../models/currency.dart';

class Localization {
  Localization._();

  static String appTitle(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '全球匯率通';
      case AppLanguage.simplifiedChinese:
        return '全球汇率通';
      case AppLanguage.english:
        return 'Global FX Tracker';
    }
  }

  static String tabSingleChart(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '走勢圖';
      case AppLanguage.simplifiedChinese:
        return '走势图';
      case AppLanguage.english:
        return 'Pair Chart';
    }
  }

  static String tabOverlayChart(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '三幣疊加';
      case AppLanguage.simplifiedChinese:
        return '三币叠加';
      case AppLanguage.english:
        return '3-FX Overlay';
    }
  }

  static String tabConversionTable(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '多幣速算表';
      case AppLanguage.simplifiedChinese:
        return '多币速算表';
      case AppLanguage.english:
        return 'Converter Table';
    }
  }

  static String fromLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '基準貨幣 (From)';
      case AppLanguage.simplifiedChinese:
        return '基准货币 (From)';
      case AppLanguage.english:
        return 'From';
    }
  }

  static String toLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '目標貨幣 (To)';
      case AppLanguage.simplifiedChinese:
        return '目标货币 (To)';
      case AppLanguage.english:
        return 'To';
    }
  }

  static String midmarketRatesNote(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '採用即時市場中間匯率 (Mid-market rates)';
      case AppLanguage.simplifiedChinese:
        return '采用实时市场中间汇率 (Mid-market rates)';
      case AppLanguage.english:
        return 'We use midmarket rates';
    }
  }

  static String chartTitleSuffix(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '匯率走勢圖';
      case AppLanguage.simplifiedChinese:
        return '汇率走势图';
      case AppLanguage.english:
        return 'Chart';
    }
  }

  static String baseCurrency(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '基準貨幣';
      case AppLanguage.simplifiedChinese:
        return '基准货币';
      case AppLanguage.english:
        return 'Base Currency';
    }
  }

  static String targetCurrency(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '目標貨幣';
      case AppLanguage.simplifiedChinese:
        return '目标货币';
      case AppLanguage.english:
        return 'Target Currency';
    }
  }

  static String downloadJpg(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '下載圖表 (JPG)';
      case AppLanguage.simplifiedChinese:
        return '下载图表 (JPG)';
      case AppLanguage.english:
        return 'Download JPG';
    }
  }

  static String exportingImage(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '正在生成高品質 JPG 圖表...';
      case AppLanguage.simplifiedChinese:
        return '正在生成高品质 JPG 图表...';
      case AppLanguage.english:
        return 'Generating high-res JPG chart...';
    }
  }

  static String exportSuccess(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '圖表已成功匯出為 JPG！';
      case AppLanguage.simplifiedChinese:
        return '图表已成功导出为 JPG！';
      case AppLanguage.english:
        return 'Chart successfully exported as JPG!';
    }
  }

  static String shareImage(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '分享圖檔';
      case AppLanguage.simplifiedChinese:
        return '分享图片';
      case AppLanguage.english:
        return 'Share Image';
    }
  }

  static String statsHigh(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '期間最高';
      case AppLanguage.simplifiedChinese:
        return '期间最高';
      case AppLanguage.english:
        return 'High';
    }
  }

  static String statsLow(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '期間最低';
      case AppLanguage.simplifiedChinese:
        return '期间最低';
      case AppLanguage.english:
        return 'Low';
    }
  }

  static String statsAvg(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '平均匯率';
      case AppLanguage.simplifiedChinese:
        return '平均汇率';
      case AppLanguage.english:
        return 'Average';
    }
  }

  static String overlayTitle(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '3 種貨幣對主幣疊加走勢';
      case AppLanguage.simplifiedChinese:
        return '3 种货币对主币叠加走势';
      case AppLanguage.english:
        return '3 Currencies Overlay Against Main';
    }
  }

  static String viewModePercent(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '百分比漲跌幅 (%)';
      case AppLanguage.simplifiedChinese:
        return '百分比涨跌幅 (%)';
      case AppLanguage.english:
        return 'Normalized % Change';
    }
  }

  static String viewModeRaw(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '各自匯率對比';
      case AppLanguage.simplifiedChinese:
        return '各自汇率对比';
      case AppLanguage.english:
        return 'Scaled Rates';
    }
  }

  static String mainCurrencyLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '主要基準幣';
      case AppLanguage.simplifiedChinese:
        return '主要基准币';
      case AppLanguage.english:
        return 'Main Base';
    }
  }

  static String addCurrency(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '新增貨幣';
      case AppLanguage.simplifiedChinese:
        return '添加货币';
      case AppLanguage.english:
        return 'Add Currency';
    }
  }

  static String searchCurrency(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '搜尋貨幣代碼或名稱...';
      case AppLanguage.simplifiedChinese:
        return '搜索货币代码或名称...';
      case AppLanguage.english:
        return 'Search currency code or name...';
    }
  }

  static String copied(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '已複製到剪貼簿';
      case AppLanguage.simplifiedChinese:
        return '已复制到剪贴板';
      case AppLanguage.english:
        return 'Copied to clipboard';
    }
  }

  static String clear(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '清除';
      case AppLanguage.simplifiedChinese:
        return '清除';
      case AppLanguage.english:
        return 'Clear';
    }
  }

  static String refresh(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '重新整理即時匯率';
      case AppLanguage.simplifiedChinese:
        return '刷新实时汇率';
      case AppLanguage.english:
        return 'Refresh Live Rates';
    }
  }

  static String lastUpdated(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '最後更新';
      case AppLanguage.simplifiedChinese:
        return '最后更新';
      case AppLanguage.english:
        return 'Last updated';
    }
  }

  static String liveIndicator(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '即時連線';
      case AppLanguage.simplifiedChinese:
        return '实时连接';
      case AppLanguage.english:
        return 'Live Connected';
    }
  }

  static String offlineFallbackIndicator(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '離線基準帳本';
      case AppLanguage.simplifiedChinese:
        return '离线基准账本';
      case AppLanguage.english:
        return 'Offline Ledger';
    }
  }

  static String changeLanguage(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '切換語言';
      case AppLanguage.simplifiedChinese:
        return '切换语言';
      case AppLanguage.english:
        return 'Language';
    }
  }

  static String swapCurrencies(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '交換貨幣';
      case AppLanguage.simplifiedChinese:
        return '交换货币';
      case AppLanguage.english:
        return 'Swap Currencies';
    }
  }

  static String selectCurrency(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '選擇貨幣';
      case AppLanguage.simplifiedChinese:
        return '选择货币';
      case AppLanguage.english:
        return 'Select Currency';
    }
  }

  static String close(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '關閉';
      case AppLanguage.simplifiedChinese:
        return '关闭';
      case AppLanguage.english:
        return 'Close';
    }
  }

  static String resetDefaults(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '恢復預設貨幣';
      case AppLanguage.simplifiedChinese:
        return '恢复默认货币';
      case AppLanguage.english:
        return 'Reset Defaults';
    }
  }

  static String latestRate(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '最新匯率';
      case AppLanguage.simplifiedChinese:
        return '最新汇率';
      case AppLanguage.english:
        return 'Latest Rate';
    }
  }

  static String selectedPoint(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '選取時點';
      case AppLanguage.simplifiedChinese:
        return '选取时点';
      case AppLanguage.english:
        return 'Selected Time';
    }
  }

  static String latestComparison(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '最新比較數值';
      case AppLanguage.simplifiedChinese:
        return '最新比较数值';
      case AppLanguage.english:
        return 'Latest Comparison';
    }
  }

  static String percentChangeVsStart(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '相對於基準點漲跌幅 (%)';
      case AppLanguage.simplifiedChinese:
        return '相对于基准点涨跌幅 (%)';
      case AppLanguage.english:
        return '% Change vs Start';
    }
  }

  static String individualTrends(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '個別標準化走勢';
      case AppLanguage.simplifiedChinese:
        return '个别标准化走势';
      case AppLanguage.english:
        return 'Individual Trends';
    }
  }

  static String settingsTitle(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '偏好與功能設定';
      case AppLanguage.simplifiedChinese:
        return '偏好与功能设置';
      case AppLanguage.english:
        return 'Preferences & Settings';
    }
  }

  static String defaultLanguageSetting(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '預設介面語言';
      case AppLanguage.simplifiedChinese:
        return '默认界面语言';
      case AppLanguage.english:
        return 'Default Interface Language';
    }
  }

  static String appearanceThemeSetting(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '外觀主題模式';
      case AppLanguage.simplifiedChinese:
        return '外观主题模式';
      case AppLanguage.english:
        return 'Appearance Theme';
    }
  }

  static String themeSystem(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '跟隨系統';
      case AppLanguage.simplifiedChinese:
        return '跟随系统';
      case AppLanguage.english:
        return 'System';
    }
  }

  static String themeLight(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '淺色';
      case AppLanguage.simplifiedChinese:
        return '浅色';
      case AppLanguage.english:
        return 'Light';
    }
  }

  static String themeDark(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '深色';
      case AppLanguage.simplifiedChinese:
        return '深色';
      case AppLanguage.english:
        return 'Dark';
    }
  }

  static String defaultBaseCurrencySetting(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '預設基準貨幣';
      case AppLanguage.simplifiedChinese:
        return '默认基准货币';
      case AppLanguage.english:
        return 'Default Base Currency';
    }
  }

  static String defaultTargetCurrencySetting(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '預設目標貨幣';
      case AppLanguage.simplifiedChinese:
        return '默认目标货币';
      case AppLanguage.english:
        return 'Default Target Currency';
    }
  }

  static String defaultTimeScaleSetting(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '預設時間跨度';
      case AppLanguage.simplifiedChinese:
        return '默认时间跨度';
      case AppLanguage.english:
        return 'Default Time Scale';
    }
  }

  static String highPrecisionMode(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '高精度小數模式 (4位以上)';
      case AppLanguage.simplifiedChinese:
        return '高精度小数模式 (4位以上)';
      case AppLanguage.english:
        return 'High-Precision Decimals (4+ digits)';
    }
  }

  static String highPrecisionDesc(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '所有貨幣顯示至少 4 位小數點精確度';
      case AppLanguage.simplifiedChinese:
        return '所有货币显示至少 4 位小数点精确度';
      case AppLanguage.english:
        return 'Show at least 4 decimal places for all currency rates';
    }
  }

  static String autoRefreshOnStart(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '開啟應用時自動更新';
      case AppLanguage.simplifiedChinese:
        return '开启应用时自动更新';
      case AppLanguage.english:
        return 'Auto-refresh Rates on Launch';
    }
  }

  static String autoRefreshDesc(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '每次啟動時自動聯網取得最新匯率';
      case AppLanguage.simplifiedChinese:
        return '每次启动时自动联网获取最新汇率';
      case AppLanguage.english:
        return 'Automatically fetch latest quotes upon opening app';
    }
  }

  static String storageAndCache(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '快取與數據管理';
      case AppLanguage.simplifiedChinese:
        return '缓存与数据管理';
      case AppLanguage.english:
        return 'Data & Cache Management';
    }
  }

  static String clearCacheAndSync(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '清除快取並重新同步';
      case AppLanguage.simplifiedChinese:
        return '清除缓存并重新同步';
      case AppLanguage.english:
        return 'Clear Cache & Re-sync';
    }
  }

  static String resetAllSettings(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '恢復出廠預設設定';
      case AppLanguage.simplifiedChinese:
        return '恢复出厂默认设置';
      case AppLanguage.english:
        return 'Reset All Settings';
    }
  }

  static String appVersionInfo(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return '歐洲央行 ECB 及香港金管局 HKMA 官方基準數據';
      case AppLanguage.simplifiedChinese:
        return '欧洲央行 ECB 及香港金管局 HKMA 官方基准数据';
      case AppLanguage.english:
        return 'Official ECB & HKMA Benchmark Data Ledger (2016-2026)';
    }
  }
}
