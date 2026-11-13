import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../models/fx_models.dart';
import '../utils/localization.dart';

class SingleLineChart extends StatefulWidget {
  const SingleLineChart({
    super.key,
    required this.points,
    required this.targetCurrency,
    required this.lang,
    required this.displayDecimals,
    required this.isIntraday,
    required this.isPositive,
    this.lineColor,
  });

  final List<RatePoint> points;
  final Currency targetCurrency;
  final AppLanguage lang;
  final int displayDecimals;
  final bool isIntraday;
  final bool isPositive;
  final Color? lineColor;

  @override
  State<SingleLineChart> createState() => _SingleLineChartState();
}

class _SingleLineChartState extends State<SingleLineChart>
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
  void didUpdateWidget(covariant SingleLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
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

  void _updateSelection(Offset localPos, double totalWidth) {
    if (widget.points.length < 2 || totalWidth <= 0) return;
    // Account for left padding (12) and right Y-axis gutter (66)
    const leftPad = 12.0;
    const rightPad = 66.0;
    final chartW = math.max(1.0, totalWidth - leftPad - rightPad);
    final fraction = ((localPos.dx - leftPad) / chartW).clamp(0.0, 1.0);
    final idx =
        (fraction * (widget.points.length - 1)).round().clamp(0, widget.points.length - 1);
    if (_selectedIndex != idx) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.points.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('No chart data available')),
      );
    }

    final points = widget.points;
    final activePoint =
        _selectedIndex != null && _selectedIndex! < points.length
            ? points[_selectedIndex!]
            : points.last;

    var minRate = points.first.rate;
    var maxRate = points.first.rate;
    for (final p in points) {
      if (p.rate < minRate) minRate = p.rate;
      if (p.rate > maxRate) maxRate = p.rate;
    }
    final rateDiff = math.max(maxRate - minRate, 0.000001);
    final midRate = (maxRate + minRate) / 2.0;
    final strokeColor = widget.lineColor ?? scheme.primary;

    final firstPt = points.first;
    final midPt = points[points.length ~/ 2];
    final lastPt = points.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scrubber / Live Value Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${activePoint.dateLabel} ${activePoint.timeLabel}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _selectedIndex == null
                        ? Localization.latestRate(widget.lang)
                        : Localization.selectedPoint(widget.lang),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    child: Text(
                      widget.targetCurrency.symbol,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    activePoint.rate.toStringAsFixed(widget.displayDecimals),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Interactive Canvas + Right-Edge Y Axis
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) =>
                  _updateSelection(d.localPosition, constraints.maxWidth),
              onTapUp: (_) => setState(() => _selectedIndex = null),
              onHorizontalDragStart: (d) =>
                  _updateSelection(d.localPosition, constraints.maxWidth),
              onHorizontalDragUpdate: (d) =>
                  _updateSelection(d.localPosition, constraints.maxWidth),
              onHorizontalDragEnd: (_) => setState(() => _selectedIndex = null),
              onHorizontalDragCancel: () =>
                  setState(() => _selectedIndex = null),
              child: SizedBox(
                height: 230,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _SingleChartPainter(
                              points: points,
                              minRate: minRate,
                              rateDiff: rateDiff,
                              lineColor: strokeColor,
                              gridColor: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.2),
                              progress: CurvedAnimation(
                                parent: _animController,
                                curve: Curves.easeOutCubic,
                              ).value,
                              selectedIndex: _selectedIndex,
                            ),
                          );
                        },
                      ),
                    ),
                    // Right-edge Y-Axis labels (High / Mid / Low)
                    Positioned(
                      right: 4,
                      top: 8,
                      bottom: 8,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            maxRate.toStringAsFixed(widget.displayDecimals),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                          Text(
                            midRate.toStringAsFixed(widget.displayDecimals),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                          Text(
                            minRate.toStringAsFixed(widget.displayDecimals),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.85),
                            ),
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

        // Timeline X-Axis Labels
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 66, top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isIntraday
                    ? '${firstPt.dateLabel} ${firstPt.timeLabel}'
                    : firstPt.dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
              Text(
                widget.isIntraday
                    ? '${midPt.dateLabel} ${midPt.timeLabel}'
                    : midPt.dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
              Text(
                widget.isIntraday
                    ? '${lastPt.dateLabel} ${lastPt.timeLabel}'
                    : lastPt.dateLabel,
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

class _SingleChartPainter extends CustomPainter {
  _SingleChartPainter({
    required this.points,
    required this.minRate,
    required this.rateDiff,
    required this.lineColor,
    required this.gridColor,
    required this.progress,
    required this.selectedIndex,
  });

  final List<RatePoint> points;
  final double minRate;
  final double rateDiff;
  final Color lineColor;
  final Color gridColor;
  final double progress;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 12.0;
    const rightPad = 66.0;
    const topPad = 12.0;
    const bottomPad = 12.0;

    final chartWidth = math.max(1.0, size.width - leftPad - rightPad);
    final chartHeight = math.max(1.0, size.height - topPad - bottomPad);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const gridLines = 4;
    for (var g = 0; g <= gridLines; g++) {
      final y = topPad + chartHeight * (g / gridLines);
      _drawDashedHorizontal(canvas, leftPad, leftPad + chartWidth, y, gridPaint);
    }

    if (points.length < 2) return;

    final coords = List<Offset>.generate(points.length, (i) {
      final x = leftPad + (i / (points.length - 1)) * chartWidth;
      final norm = ((points[i].rate - minRate) / rateDiff).clamp(0.0, 1.0);
      final targetY = topPad + chartHeight - (norm * chartHeight);
      final currentY =
          (topPad + chartHeight) - ((topPad + chartHeight) - targetY) * progress;
      return Offset(x, currentY);
    });

    final curvePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    final fillPath = Path()
      ..moveTo(coords.first.dx, topPad + chartHeight)
      ..lineTo(coords.first.dx, coords.first.dy);

    for (var i = 1; i < coords.length; i++) {
      final prev = coords[i - 1];
      final curr = coords[i];
      final midX = (prev.dx + curr.dx) / 2;
      curvePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
      fillPath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    fillPath
      ..lineTo(coords.last.dx, topPad + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(curvePath, strokePaint);

    final activeIdx = selectedIndex ?? (coords.length - 1);
    final activeCoord = coords[activeIdx.clamp(0, coords.length - 1)];

    if (selectedIndex != null) {
      _drawDashedVertical(
        canvas,
        activeCoord.dx,
        topPad,
        topPad + chartHeight,
        Paint()
          ..color = lineColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.5,
      );
    }

    canvas.drawCircle(
      activeCoord,
      8,
      Paint()..color = lineColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(activeCoord, 4, Paint()..color = lineColor);
    canvas.drawCircle(activeCoord, 2, Paint()..color = Colors.white);
  }

  void _drawDashedHorizontal(
    Canvas canvas,
    double startX,
    double endX,
    double y,
    Paint paint,
  ) {
    var x = startX;
    const dash = 5.0;
    const gap = 5.0;
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
    const dash = 6.0;
    const gap = 5.0;
    while (y < endY) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + dash, endY)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SingleChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor;
  }
}
