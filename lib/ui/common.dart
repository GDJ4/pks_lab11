import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF241E35);
  static const panel = Color(0xFF1A1829);
  static const purple = Color(0xFF5B1285);
  static const pink = Color(0xFFFF4F8A);
  static const pinkLight = Color(0xFFFF6A9E);
}

/// Кастомная иконка блокнота (одинарный, 3 пружины).
class NotebookIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  const NotebookIcon({
    super.key,
    this.size = 140,
    this.color = AppColors.pink,
    this.strokeWidth = 6,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _NotebookPainter(color, strokeWidth),
  );
}

class _NotebookPainter extends CustomPainter {
  final Color color;
  final double w;
  _NotebookPainter(this.color, this.w);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromLTWH(
      s.width * .22,
      s.height * .24,
      s.width * .56,
      s.height * .56,
    );
    final r = RRect.fromRectAndRadius(rect, Radius.circular(s.width * .10));
    c.drawRRect(r, p);

    final top = r.outerRect.top;
    final left = r.outerRect.left;
    final step = r.outerRect.width / 4;
    for (int i = 0; i < 3; i++) {
      final x = left + step * (i + .7);
      c.drawCircle(Offset(x, top - s.height * .06), w / 1.6, p);
      c.drawLine(
        Offset(x, top - s.height * .03),
        Offset(x, top + s.height * .03),
        p,
      );
    }

    final startX = left + s.width * .06;
    final endX = left + r.outerRect.width - s.width * .06;
    double y = r.outerRect.top + s.height * .12;
    for (int i = 0; i < 4; i++) {
      c.drawLine(Offset(startX, y), Offset(endX, y), p);
      y += s.height * .11;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
