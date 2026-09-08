import 'dart:math';
import 'package:flutter/material.dart';
import '../services/caregiver_service.dart';

class CognitiveLineChart extends StatefulWidget {
  final List<TrendPoint> trend;
  final String selectedMetric;
  final ValueChanged<String> onMetricChanged;

  const CognitiveLineChart({
    super.key,
    required this.trend,
    required this.selectedMetric,
    required this.onMetricChanged,
  });

  @override
  State<CognitiveLineChart> createState() => _CognitiveLineChartState();
}

class _CognitiveLineChartState extends State<CognitiveLineChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.trend.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, color: Colors.grey.shade400, size: 36),
            const SizedBox(height: 8),
            Text(
              'No calibration test data recorded yet.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All Metrics', const Color(0xFF23654D)),
              const SizedBox(width: 8),
              _buildFilterChip('MEMORY', 'Memory', const Color(0xFF23654D)),
              const SizedBox(width: 8),
              _buildFilterChip('ATTENTION', 'Attention', const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildFilterChip('ENGAGEMENT', 'Engagement', const Color(0xFFD97706)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Line chart container
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 200),
            painter: _ChartPainter(
              trend: widget.trend,
              selectedMetric: widget.selectedMetric,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Metric legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.selectedMetric == 'ALL' || widget.selectedMetric == 'MEMORY')
              _buildLegendItem('Memory', const Color(0xFF23654D)),
            if (widget.selectedMetric == 'ALL') const SizedBox(width: 16),
            if (widget.selectedMetric == 'ALL' || widget.selectedMetric == 'ATTENTION')
              _buildLegendItem('Attention', const Color(0xFF0284C7)),
            if (widget.selectedMetric == 'ALL') const SizedBox(width: 16),
            if (widget.selectedMetric == 'ALL' || widget.selectedMetric == 'ENGAGEMENT')
              _buildLegendItem('Engagement', const Color(0xFFD97706)),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, Color accentColor) {
    final isSelected = widget.selectedMetric == key;
    return GestureDetector(
      onTap: () => widget.onMetricChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : const Color(0xFFF1EFE3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1F4D36),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<TrendPoint> trend;
  final String selectedMetric;

  _ChartPainter({
    required this.trend,
    required this.selectedMetric,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = 34.0;
    final bottomPadding = 24.0;
    final topPadding = 12.0;
    final rightPadding = 12.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Gridlines & Y-axis labels (0, 25, 50, 75, 100)
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F3F5)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: Colors.grey.shade500,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final ySteps = [0, 25, 50, 75, 100];
    for (final step in ySteps) {
      final y = topPadding + chartHeight * (1.0 - step / 100.0);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final textSpan = TextSpan(text: '$step', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    if (trend.isEmpty) return;

    // X coordinates
    final n = trend.length;
    final dx = n > 1 ? chartWidth / (n - 1) : chartWidth / 2;

    double getX(int i) {
      return n > 1 ? leftPadding + i * dx : leftPadding + chartWidth / 2;
    }

    double getY(double val) {
      final clamped = val.clamp(0.0, 100.0);
      return topPadding + chartHeight * (1.0 - clamped / 100.0);
    }

    // Draw lines
    if (selectedMetric == 'ALL' || selectedMetric == 'MEMORY') {
      _drawSeries(
        canvas: canvas,
        points: List.generate(n, (i) => Offset(getX(i), getY(trend[i].memory))),
        color: const Color(0xFF23654D),
        fillGradient: true,
        bottomY: topPadding + chartHeight,
      );
    }

    if (selectedMetric == 'ALL' || selectedMetric == 'ATTENTION') {
      _drawSeries(
        canvas: canvas,
        points: List.generate(n, (i) => Offset(getX(i), getY(trend[i].attention))),
        color: const Color(0xFF0284C7),
        fillGradient: selectedMetric == 'ATTENTION',
        bottomY: topPadding + chartHeight,
      );
    }

    if (selectedMetric == 'ALL' || selectedMetric == 'ENGAGEMENT') {
      _drawSeries(
        canvas: canvas,
        points: List.generate(n, (i) => Offset(getX(i), getY(trend[i].engagement))),
        color: const Color(0xFFD97706),
        fillGradient: selectedMetric == 'ENGAGEMENT',
        bottomY: topPadding + chartHeight,
      );
    }

    // X-axis date labels (show every few points to avoid crowding)
    final labelInterval = max(1, (n / 5).ceil());
    for (int i = 0; i < n; i++) {
      if (i == 0 || i == n - 1 || i % labelInterval == 0) {
        final rawDate = trend[i].date;
        String displayDate = rawDate;
        if (rawDate.contains('-')) {
          final parts = rawDate.split('-');
          if (parts.length >= 3) {
            displayDate = '${parts[1]}/${parts[2]}';
          }
        }
        final textSpan = TextSpan(text: displayDate, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(getX(i) - textPainter.width / 2, topPadding + chartHeight + 6),
        );
      }
    }
  }

  void _drawSeries({
    required Canvas canvas,
    required List<Offset> points,
    required Color color,
    required bool fillGradient,
    required double bottomY,
  }) {
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 1) {
      // Just one dot
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cx = (p0.dx + p1.dx) / 2;
        path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      }
    }

    // Draw subtle gradient fill if single metric or primary
    if (fillGradient && points.length > 1) {
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, bottomY)
        ..lineTo(points.first.dx, bottomY)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 500, bottomY))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(path, linePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.0, dotPaint);
      canvas.drawCircle(pt, 4.0, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.trend != trend || oldDelegate.selectedMetric != selectedMetric;
  }
}
