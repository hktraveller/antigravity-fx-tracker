import 'currency.dart';

enum TimeScale {
  oneDay('1D', '1天', '1天', '1D', 24),
  oneWeek('1W', '1週', '1周', '1W', 28),
  oneMonth('1M', '1個月', '1个月', '1M', 30),
  oneYear('1Y', '1年', '1年', '1Y', 52),
  fiveYears('5Y', '5年', '5年', '5Y', 60),
  tenYears('10Y', '10年', '10年', '10Y', 120);

  const TimeScale(
    this.code,
    this.labelZhTw,
    this.labelZhCn,
    this.labelEn,
    this.pointsCount,
  );

  final String code;
  final String labelZhTw;
  final String labelZhCn;
  final String labelEn;
  final int pointsCount;

  String getLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.traditionalChinese:
        return labelZhTw;
      case AppLanguage.simplifiedChinese:
        return labelZhCn;
      case AppLanguage.english:
        return labelEn;
    }
  }

  static TimeScale fromCode(String? code) {
    if (code == null) return TimeScale.oneMonth;
    return TimeScale.values.firstWhere(
      (e) => e.code.toLowerCase() == code.toLowerCase(),
      orElse: () => TimeScale.oneMonth,
    );
  }
}

class RatePoint {
  const RatePoint({
    required this.timestampMs,
    required this.dateLabel,
    required this.timeLabel,
    required this.rate,
  });

  final int timestampMs;
  final String dateLabel;
  final String timeLabel;
  final double rate;

  RatePoint copyWith({
    int? timestampMs,
    String? dateLabel,
    String? timeLabel,
    double? rate,
  }) {
    return RatePoint(
      timestampMs: timestampMs ?? this.timestampMs,
      dateLabel: dateLabel ?? this.dateLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      rate: rate ?? this.rate,
    );
  }
}

class SinglePairStats {
  const SinglePairStats({
    required this.currentRate,
    required this.initialRate,
    required this.change,
    required this.changePercent,
    required this.minRate,
    required this.maxRate,
    required this.avgRate,
  });

  final double currentRate;
  final double initialRate;
  final double change;
  final double changePercent;
  final double minRate;
  final double maxRate;
  final double avgRate;

  static const empty = SinglePairStats(
    currentRate: 1.0,
    initialRate: 1.0,
    change: 0.0,
    changePercent: 0.0,
    minRate: 1.0,
    maxRate: 1.0,
    avgRate: 1.0,
  );
}

class OverlayCurrencyData {
  const OverlayCurrencyData({
    required this.currency,
    required this.colorValue,
    required this.points,
    required this.normalizedPoints,
    required this.latestRate,
    required this.changePercent,
    required this.minRate,
    required this.maxRate,
  });

  final Currency currency;
  final int colorValue;
  final List<RatePoint> points;
  final List<RatePoint> normalizedPoints;
  final double latestRate;
  final double changePercent;
  final double minRate;
  final double maxRate;
}

enum ApiConnectionStatus {
  connecting,
  live,
  fallback,
  error,
}
