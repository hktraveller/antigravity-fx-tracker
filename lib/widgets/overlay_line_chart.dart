import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../models/fx_models.dart';
import '../utils/localization.dart';

class OverlayLineChart extends StatefulWidget {
  const OverlayLineChart({
    super.key,
    required this.mainCurrency,
    required this.overlayData,
    required this.isNormalizedView,
    required this.lang,
  });

  final Currency mainCurrency;
  final List<OverlayCurrencyData> overlayData;
  final bool isNormalizedView;
  final AppLanguage lang;

  @override
  State<OverlayLineChart> createState() => _OverlayLineChartState();
}

class _OverlayLineChartState extends State<OverlayLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant OverlayLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlayData != widget.overlayData ||
        oldWidget.isNormalizedView != widget.isNormalizedView) {
      _selectedIndex = null;
      _animController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateSelection(Offset localPos, double totalWidth, int pointCount) {
    if (pointCount < 2 || totalWidth <= 0) return;
    const pad = 16.0;
    final chartW = math.max(1.0, totalWidth - pad * 2);
    final frac = ((localPos.dx - pad) / chartW).clamp(0.0, 1.0);
    final idx = (frac * (pointCount - 1)).round().clamp(0, pointCount - 1);
    if (_selectedIndex != idx) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.overlayData.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('No comparison data')),
      );
    }

    final samplePoints = widget.overlayData.first.points;
    final pointCount = samplePoints.length;
    final activeIdx =
        (_selectedIndex ?? (pointCount - 1)).clamp(0, math.max(0, pointCount - 1));
    final activeDate = samplePoints.isNotEmpty
        ? '${samplePoints[activeIdx].dateLabel} ${samplePoints[activeIdx].timeLabel}'
        : '';

    var minVal = -5.0;
    var maxVal = 5.0;
    if (widget.isNormalizedView) {
      final allVals = widget.overlayData
          .expand((e) => e.normalizedPoints.map((p) => p.rate))
          .toList();
      if (allVals.isNotEmpty) {
        minVal = allVals.reduce(math.min);
        maxVal = allVals.reduce(math.max);
        if (maxVal <= minVal) {
          maxVal += 2.0;
          minVal -= 2.0;
        }
      }
    } else {
      minVal = 0.0;
      maxVal = 1.0;
    }
    final diffVal = math.max(maxVal - minVal, 0.0001);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Legend & Live Scrubber Banner
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedIndex == null
                        ? Localization.latestComparison(widget.lang)
                        : '${Localization.selectedPoint(widget.lang)}: $activeDate',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.isNormalizedView
                        ? Localization.percentChangeVsStart(widget.lang)
                        : Localization.individualTrends(widget.lang),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.overlayData.map((item) {
                  final val = widget.isNormalizedView
                      ? (activeIdx < item.normalizedPoints.length
                          ? item.normalizedPoints[activeIdx].rate
                          : 0.0)
                      : (activeIdx < item.points.length
                          ? item.points[activeIdx].rate
                          : item.latestRate);
                  final isUp = val >= 0;
                  final sign = isUp ? '+' : '';

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(item.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.currency.flag} ${item.currency.code}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (widget.isNormalizedView)
                          Text(
                            '$sign${val.toStringAsFixed(2)}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isUp
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          )
                        else
                          Text(
                            '${item.currency.symbol}${val.toStringAsFixed(item.currency.defaultDecimals)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Overlay Canvas
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _updateSelection(
                  d.localPosition, constraints.maxWidth, pointCount),
              onTapUp: (_) => setState(() => _selectedIndex = null),
              onHorizontalDragStart: (d) => _updateSelection(
                  d.localPosition, constraints.maxWidth, pointCount),
              onHorizontalDragUpdate: (d) => _updateSelection(
                  d.localPosition, constraints.maxWidth, pointCount),
              onHorizontalDragEnd: (_) => setState(() => _selectedIndex = null),
              onHorizontalDragCancel: () =>
                  setState(() => _selectedIndex = null),
              child: SizedBox(
                height: 245,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _OverlayChartPainter(
                        overlayData: widget.overlayData,
                        isNormalizedView: widget.isNormalizedView,
                        minVal: minVal,
                        diffVal: diffVal,
                        gridColor:
                            scheme.onSurfaceVariant.withValues(alpha: 0.2),
                        scrubberColor: scheme.primary.withValues(alpha: 0.7),
                        progress: CurvedAnimation(
                          parent: _animController,
                          curve: Curves.easeOutCubic,
                        ).value,
                        selectedIndex: _selectedIndex,
                        activeIndex: activeIdx,
                        pointCount: pointCount,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),

        // Timeline edge dates
        if (samplePoints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  samplePoints.first.dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
                Text(
                  samplePoints[samplePoints.length ~/ 2].dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
                Text(
                  samplePoints.last.dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OverlayChartPainter extends CustomPainter {
  _OverlayChartPainter({
    required this.overlayData,
    required this.isNormalizedView,
    required this.minVal,
    required this.diffVal,
    required this.gridColor,
    required this.scrubberColor,
    required this.progress,
    required this.selectedIndex,
    required this.activeIndex,
    required this.pointCount,
  });

  final List<OverlayCurrencyData> overlayData;
  final bool isNormalizedView;
  final double minVal;
  final double diffVal;
  final Color gridColor;
  final Color scrubberColor;
  final double progress;
  final int? selectedIndex;
  final int activeIndex;
  final int pointCount;

  @override
  void paint(Canvas canvas, Size size) {
    const hPad = 16.0;
    const vPad = 12.0;
    final chartWidth = math.max(1.0, size.width - hPad * 2);
    final chartHeight = math.max(1.0, size.height - vPad * 2);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (var g = 0; g <= 4; g++) {
      final y = vPad + chartHeight * (g / 4);
      _drawDashedHorizontal(canvas, hPad, hPad + chartWidth, y, gridPaint);
    }

    if (isNormalizedView) {
      final zeroRatio = (0.0 - minVal) / diffVal;
      if (zeroRatio >= 0 && zeroRatio <= 1) {
        final zeroY = vPad + chartHeight - (zeroRatio * chartHeight);
        _drawDashedHorizontal(
          canvas,
          hPad,
          hPad + chartWidth,
          zeroY,
          Paint()
            ..color = Colors.grey.withValues(alpha: 0.5)
            ..strokeWidth = 1.5,
          dash: 10,
          gap: 8,
        );
      }
    }

    for (final item in overlayData) {
      final pts = isNormalizedView ? item.normalizedPoints : item.points;
      if (pts.length < 2) continue;

      final itemMin = isNormalizedView
          ? minVal
          : pts.map((e) => e.rate).reduce(math.min);
      final itemMax = isNormalizedView
          ? minVal + diffVal
          : pts.map((e) => e.rate).reduce(math.max);
      final itemDiff = math.max(itemMax - itemMin, 0.0001);
      final strokeColor = Color(item.colorValue);

      final coords = List<Offset>.generate(pts.length, (idx) {
        final x = hPad + (idx / (pts.length - 1)) * chartWidth;
        final norm = ((pts[idx].rate - itemMin) / itemDiff).clamp(0.0, 1.0);
        final targetY = vPad + chartHeight - (norm * chartHeight);
        final currY =
            (vPad + chartHeight) - ((vPad + chartHeight) - targetY) * progress;
        return Offset(x, currY);
      });

      final path = Path()..moveTo(coords.first.dx, coords.first.dy);
      for (var i = 1; i < coords.length; i++) {
        final prev = coords[i - 1];
        final curr = coords[i];
        final midX = (prev.dx + curr.dx) / 2;
        path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..strokeWidth = 2.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      final dotCoord = coords[activeIndex.clamp(0, coords.length - 1)];
      canvas.drawCircle(dotCoord, 4, Paint()..color = strokeColor);
      canvas.drawCircle(dotCoord, 2, Paint()..color = Colors.white);
    }

    if (selectedIndex != null && pointCount > 1) {
      final activeX = hPad + (activeIndex / (pointCount - 1)) * chartWidth;
      _drawDashedVertical(
        canvas,
        activeX,
        vPad,
        vPad + chartHeight,
        Paint()
          ..color = scrubberColor
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawDashedHorizontal(
    Canvas canvas,
    double startX,
    double endX,
    double y,
    Paint paint, {
    double dash = 6,
    double gap = 6,
  }) {
    var x = startX;
    while (x < endX) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, endX), y),
        paint,
      );
      x += dash + gap;
    }
  }

  void _drawDashedVertical(
    Canvas canvas,
    double x,
    double startY,
    double endY,
    Paint paint,
  ) {
    var y = startY;
    while (y < endY) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + 6, endY)),
        paint,
      );
      y += 11;
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayChartPainter oldDelegate) {
    return oldDelegate.overlayData != overlayData ||
        oldDelegate.isNormalizedView != isNormalizedView ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
