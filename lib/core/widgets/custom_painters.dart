import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RadarChartWidget
// Hexagonal spider/radar chart used on the Rank screen.
// Each axis has a small hexagonal icon showing the relevant muscle group.
// ─────────────────────────────────────────────────────────────────────────────

class RadarChartWidget extends StatelessWidget {
  final List<RadarPoint> points;
  const RadarChartWidget({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cx = constraints.maxWidth / 2;
        final cy = constraints.maxHeight / 2;
        final radius = constraints.maxWidth * 0.28;

        return RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadarPainter(points: points, radius: radius),
                ),
              ),
              ...List.generate(points.length, (i) {
                final angle = (2 * pi * i / points.length) - (pi / 2);
                final labelR = radius + 42;
                final double x = cx + labelR * cos(angle);
                final double y = cy + labelR * sin(angle);

                final lbl = points[i].label.toLowerCase();
                // Smart Front/Back Mapping
                final backMuscles = ['back', 'triceps', 'hamstrings', 'glutes', 'calves'];
                final isFront = !backMuscles.contains(lbl);
                
                final color = AppColors.getRankColor(points[i].rank);

                return Positioned(
                  left: x - 40,
                  top: y - 40,
                  width: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HexagonIcon(muscle: lbl, isFront: isFront, color: color),
                      const SizedBox(height: 6),
                      Text(
                        points[i].label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HexagonIcon
// A small hexagonal badge showing a highlighted muscle via flutter_body_atlas.
// ─────────────────────────────────────────────────────────────────────────────

class _HexagonIcon extends StatelessWidget {
  final String muscle;
  final bool isFront;
  final Color color;
  const _HexagonIcon({required this.muscle, required this.isFront, required this.color});

  @override
  Widget build(BuildContext context) {
    // Map code names to asset filenames
    String assetName = muscle.toLowerCase();
    if (assetName == 'shoulders') assetName = 'sholders'; // Handle user spelling
    
    final assetPath = 'assets/radar_images/$assetName.png';

    return RepaintBoundary(
      child: SizedBox(
        width: 44,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 28, spreadRadius: 4),
                ],
              ),
            ),
            // Hexagon clipped image
            ClipPath(
              clipper: _HexagonClipper(),
              child: Container(
                width: 64,
                height: 74,
                color: const Color(0xFF16213E),
                alignment: Alignment.center,
                child: Image.asset(
                  assetPath,
                  width: 64,
                  height: 74,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.bolt_rounded, color: color, size: 36),
                ),
              ),
            ),
            // Hexagon stroke outline
            CustomPaint(
              size: const Size(64, 74),
              painter: _HexagonOutlinePainter(color: color, strokeWidth: 2.0),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width, h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexagonOutlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _HexagonOutlinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width, h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _HexagonOutlinePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class RadarPoint {
  final String label;
  final double value; // 0–100
  final String rank;
  const RadarPoint(this.label, this.value, this.rank);
}

// ─────────────────────────────────────────────────────────────────────────────
// _RadarPainter
// ─────────────────────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final List<RadarPoint> points;
  final double radius;
  _RadarPainter({required this.points, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final n = points.length;

    // Grid rings
    for (int ring = 1; ring <= 5; ring++) {
      final r = radius * ring / 5;
      _drawPolygon(
        canvas,
        center,
        r,
        n,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Axis lines
    for (int i = 0; i < n; i++) {
      final angle = _angleOf(i, n);
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        Paint()..color = Colors.white.withValues(alpha: 0.08)..strokeWidth = 1,
      );
    }

    // Filled data polygon
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = _angleOf(i, n);
      final r = radius * points[i].value / 100;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = AppColors.blue.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = AppColors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Data point dots
    for (int i = 0; i < n; i++) {
      final angle = _angleOf(i, n);
      final r = radius * points[i].value / 100;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      final dotColor = AppColors.getRankColor(points[i].rank);
      canvas.drawCircle(p, 8, Paint()..color = dotColor.withValues(alpha: 0.25)..style = PaintingStyle.fill);
      canvas.drawCircle(p, 5, Paint()..color = dotColor..style = PaintingStyle.fill);
      canvas.drawCircle(p, 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  double _angleOf(int i, int n) => (2 * pi * i / n) - (pi / 2);

  void _drawPolygon(Canvas canvas, Offset center, double r, int n, Paint paint) {
    final path = Path();
    for (int i = 0; i < n; i++) {
      final a = _angleOf(i, n);
      final p = Offset(center.dx + r * cos(a), center.dy + r * sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.points != points;
}
