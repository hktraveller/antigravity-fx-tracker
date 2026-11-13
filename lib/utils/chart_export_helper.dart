import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/currency.dart';
import '../models/fx_models.dart';
import 'localization.dart';

class ChartExportHelper {
  ChartExportHelper._();

  static Future<String> exportSingleChartAsJpg({
    required Currency baseCurrency,
    required Currency targetCurrency,
    required TimeScale scale,
    required List<RatePoint> points,
    required SinglePairStats stats,
    required AppLanguage lang,
    required bool isDarkTheme,
    required int displayDecimals,
  }) async {
    const width = 1200;
    const height = 800;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    final bgColor =
        isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor =
        isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final borderColor =
        isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryText =
        isDarkTheme ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryText =
        isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final gridColor =
        isDarkTheme ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final isPositive = stats.changePercent >= 0;
    final trendColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = bgColor,
    );

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 40, width - 80.0, height - 80.0),
      const Radius.circular(24),
    );
    canvas.drawRRect(cardRect, Paint()..color = cardColor);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawText(
      canvas,
      '${baseCurrency.flag} ${baseCurrency.code} → ${targetCurrency.flag} ${targetCurrency.code} (${scale.getLabel(lang)})',
      const Offset(70, 68),
      TextStyle(
        color: primaryText,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );

    final stamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    _drawText(
      canvas,
      '${Localization.appTitle(lang)}  |  ${Localization.lastUpdated(lang)}: $stamp',
      const Offset(70, 114),
      TextStyle(color: secondaryText, fontSize: 20),
    );

    final formattedRate = stats.currentRate.toStringAsFixed(displayDecimals);
    _drawText(
      canvas,
      '${targetCurrency.symbol} $formattedRate',
      const Offset(70, 158),
      TextStyle(
        color: primaryText,
        fontSize: 44,
        fontWeight: FontWeight.bold,
      ),
    );

    final sign = isPositive ? '+' : '';
    final changeStr =
        '$sign${stats.changePercent.toStringAsFixed(2)}% ($sign${stats.change.toStringAsFixed(displayDecimals)})';
    _drawText(
      canvas,
      changeStr,
      const Offset(430, 170),
      TextStyle(
        color: trendColor,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    );

    final metrics = [
      '${Localization.statsHigh(lang)}: ${stats.maxRate.toStringAsFixed(displayDecimals)}',
      '${Localization.statsLow(lang)}: ${stats.minRate.toStringAsFixed(displayDecimals)}',
      '${Localization.statsAvg(lang)}: ${stats.avgRate.toStringAsFixed(displayDecimals)}',
    ];
    for (var i = 0; i < metrics.length; i++) {
      _drawText(
        canvas,
        metrics[i],
        Offset(70.0 + i * 340.0, 224),
        TextStyle(color: secondaryText, fontSize: 20),
      );
    }

    const chartLeft = 80.0;
    const chartTop = 285.0;
    const chartRight = width - 80.0;
    const chartBottom = height - 105.0;
    const chartWidth = chartRight - chartLeft;
    const chartHeight = chartBottom - chartTop;

    final minR = stats.minRate;
    final maxR = stats.maxRate;
    final rDiff = math.max(maxR - minR, 0.000001);

    const gridSteps = 4;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.5;

    for (var g = 0; g <= gridSteps; g++) {
      final ratio = g / gridSteps;
      final y = chartBottom - ratio * chartHeight;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      final val = minR + ratio * rDiff;
      _drawText(
        canvas,
        val.toStringAsFixed(displayDecimals),
        Offset(chartRight - 115, y - 22),
        TextStyle(color: secondaryText, fontSize: 17),
      );
    }

    if (points.length >= 2) {
      final linePath = Path();
      final fillPath = Path();
      final count = points.length;

      for (var i = 0; i < count; i++) {
        final p = points[i];
        final px = chartLeft + (i / (count - 1)) * chartWidth;
        final py = chartBottom -
            (((p.rate - minR) / rDiff) * chartHeight).clamp(0.0, chartHeight);
        if (i == 0) {
          linePath.moveTo(px, py);
          fillPath.moveTo(px, chartBottom);
          fillPath.lineTo(px, py);
        } else {
          final prev = points[i - 1];
          final prevX = chartLeft + ((i - 1) / (count - 1)) * chartWidth;
          final prevY = chartBottom -
              (((prev.rate - minR) / rDiff) * chartHeight)
                  .clamp(0.0, chartHeight);
          final midX = (prevX + px) / 2;
          linePath.cubicTo(midX, prevY, midX, py, px, py);
          fillPath.cubicTo(midX, prevY, midX, py, px, py);
        }
      }
      fillPath.lineTo(chartRight, chartBottom);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, chartTop),
          const Offset(0, chartBottom),
          [
            trendColor.withValues(alpha: isDarkTheme ? 0.38 : 0.28),
            trendColor.withValues(alpha: 0.0),
          ],
        );
      canvas.drawPath(fillPath, fillPaint);

      canvas.drawPath(
        linePath,
        Paint()
          ..color = trendColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    if (points.isNotEmpty) {
      final isIntraday = scale == TimeScale.oneDay;
      final firstLbl = isIntraday
          ? '${points.first.dateLabel} ${points.first.timeLabel}'
          : points.first.dateLabel;
      final midPt = points[points.length ~/ 2];
      final midLbl = isIntraday
          ? '${midPt.dateLabel} ${midPt.timeLabel}'
          : midPt.dateLabel;
      final lastLbl = isIntraday
          ? '${points.last.dateLabel} ${points.last.timeLabel}'
          : points.last.dateLabel;

      _drawText(
        canvas,
        firstLbl,
        const Offset(chartLeft, height - 88),
        TextStyle(color: secondaryText, fontSize: 18),
      );
      _drawText(
        canvas,
        midLbl,
        const Offset(chartLeft + chartWidth / 2 - 55, height - 88),
        TextStyle(color: secondaryText, fontSize: 18),
      );
      _drawText(
        canvas,
        lastLbl,
        const Offset(chartRight - 120, height - 88),
        TextStyle(color: secondaryText, fontSize: 18),
      );
    }

    final fileName =
        'FX_${baseCurrency.code}_${targetCurrency.code}_${scale.code}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _savePictureAsJpg(recorder, width, height, fileName);
  }

  static Future<String> exportOverlayChartAsJpg({
    required Currency mainBase,
    required TimeScale scale,
    required List<OverlayCurrencyData> overlayData,
    required AppLanguage lang,
    required bool isDarkTheme,
  }) async {
    const width = 1200;
    const height = 850;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    final bgColor =
        isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor =
        isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final borderColor =
        isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryText =
        isDarkTheme ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryText =
        isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final gridColor =
        isDarkTheme ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = bgColor,
    );

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 40, width - 80.0, height - 80.0),
      const Radius.circular(24),
    );
    canvas.drawRRect(cardRect, Paint()..color = cardColor);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawText(
      canvas,
      '${Localization.overlayTitle(lang)} (${scale.getLabel(lang)})',
      const Offset(70, 68),
      TextStyle(
        color: primaryText,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
    );

    final compareCodes = overlayData.map((e) => e.currency.code).join(' + ');
    _drawText(
      canvas,
      '${mainBase.flag} ${mainBase.code}  vs  $compareCodes  |  ${Localization.viewModePercent(lang)}',
      const Offset(70, 112),
      TextStyle(color: secondaryText, fontSize: 19),
    );

    for (var i = 0; i < overlayData.length; i++) {
      final item = overlayData[i];
      final legX = 70.0 + i * 360.0;
      const legY = 166.0;
      canvas.drawCircle(
        Offset(legX + 10, legY + 12),
        9,
        Paint()..color = Color(item.colorValue),
      );
      final sign = item.changePercent >= 0 ? '+' : '';
      final text =
          '${item.currency.flag} ${item.currency.code}: ${item.currency.symbol}${item.latestRate.toStringAsFixed(2)} ($sign${item.changePercent.toStringAsFixed(2)}%)';
      _drawText(
        canvas,
        text,
        Offset(legX + 28, legY),
        TextStyle(
          color: primaryText,
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    const chartLeft = 80.0;
    const chartTop = 230.0;
    const chartRight = width - 80.0;
    const chartBottom = height - 105.0;
    const chartWidth = chartRight - chartLeft;
    const chartHeight = chartBottom - chartTop;

    final allNorm =
        overlayData.expand((e) => e.normalizedPoints.map((p) => p.rate)).toList();
    var minP = allNorm.isNotEmpty ? allNorm.reduce(math.min) : -5.0;
    var maxP = allNorm.isNotEmpty ? allNorm.reduce(math.max) : 5.0;
    if (maxP <= minP) {
      maxP += 2.0;
      minP -= 2.0;
    }
    final diffP = math.max(maxP - minP, 0.01);

    const gridSteps = 5;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.5;

    for (var g = 0; g <= gridSteps; g++) {
      final ratio = g / gridSteps;
      final y = chartBottom - ratio * chartHeight;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      final val = minP + ratio * diffP;
      final sign = val >= 0 ? '+' : '';
      _drawText(
        canvas,
        '$sign${val.toStringAsFixed(1)}%',
        Offset(chartRight - 90, y - 22),
        TextStyle(color: secondaryText, fontSize: 17),
      );
    }

    final zeroRatio = (0.0 - minP) / diffP;
    if (zeroRatio >= 0 && zeroRatio <= 1) {
      final zeroY = chartBottom - zeroRatio * chartHeight;
      _drawDashedLine(
        canvas,
        Offset(chartLeft, zeroY),
        Offset(chartRight, zeroY),
        Paint()
          ..color = secondaryText
          ..strokeWidth = 2,
      );
    }

    for (final item in overlayData) {
      final pts = item.normalizedPoints;
      if (pts.length < 2) continue;
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final px = chartLeft + (i / (pts.length - 1)) * chartWidth;
        final py = chartBottom -
            (((pts[i].rate - minP) / diffP) * chartHeight)
                .clamp(0.0, chartHeight);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          final prevX = chartLeft + ((i - 1) / (pts.length - 1)) * chartWidth;
          final prevY = chartBottom -
              (((pts[i - 1].rate - minP) / diffP) * chartHeight)
                  .clamp(0.0, chartHeight);
          final midX = (prevX + px) / 2;
          path.cubicTo(midX, prevY, midX, py, px, py);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(item.colorValue)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    final stamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    _drawText(
      canvas,
      'Generated by ${Localization.appTitle(lang)}  |  $stamp',
      const Offset(chartLeft, height - 85),
      TextStyle(color: secondaryText, fontSize: 18),
    );

    final fileName =
        'FX_Overlay_${mainBase.code}_${scale.code}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _savePictureAsJpg(recorder, width, height, fileName);
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, offset);
  }

  static void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dash = 10,
    double gap = 8,
  }) {
    final total = (end - start).distance;
    final dir = (end - start) / total;
    var dist = 0.0;
    while (dist < total) {
      final segEnd = math.min(dist + dash, total);
      canvas.drawLine(start + dir * dist, start + dir * segEnd, paint);
      dist += dash + gap;
    }
  }

  static Future<String> _savePictureAsJpg(
    ui.PictureRecorder recorder,
    int width,
    int height,
    String fileName,
  ) async {
    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(width, height);
    final byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw StateError('Failed to rasterize chart image');
    }

    final rawBytes = byteData.buffer.asUint8List();
    final encodedImg = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rawBytes.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    final jpgBytes = Uint8List.fromList(img.encodeJpg(encodedImg, quality: 95));

    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/FxRates');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(jpgBytes, flush: true);
    return file.path;
  }

  static Future<void> shareExportedJpg(String filePath) async {
    await Share.shareXFiles([XFile(filePath, mimeType: 'image/jpeg')]);
  }
}
