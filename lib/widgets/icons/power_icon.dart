import 'package:flutter/material.dart';

/// 功率图标 (心电图/波形)
class PowerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PowerIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PowerPainter(color: color),
    );
  }
}

class _PowerPainter extends CustomPainter {
  final Color color;

  _PowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1024;

    final path = Path();

    // 波形路径
    path.moveTo(800 * scale, 544 * scale);
    path.lineTo(697.6 * scale, 544 * scale);
    path.lineTo(640 * scale, 313.6 * scale);
    path.cubicTo(633.6 * scale, 300.8 * scale, 620.8 * scale, 288 * scale,
        608 * scale, 288 * scale);
    path.cubicTo(595.2 * scale, 288 * scale, 582.4 * scale, 294.4 * scale,
        576 * scale, 307.2 * scale);
    path.lineTo(486.4 * scale, 588.8 * scale);
    path.lineTo(448 * scale, 441.6 * scale);
    path.cubicTo(441.6 * scale, 428.8 * scale, 428.8 * scale, 416 * scale,
        416 * scale, 416 * scale);
    path.cubicTo(403.2 * scale, 416 * scale, 390.4 * scale, 422.4 * scale,
        384 * scale, 435.2 * scale);
    path.lineTo(332.8 * scale, 544 * scale);
    path.lineTo(224 * scale, 544 * scale);
    path.cubicTo(204.8 * scale, 544 * scale, 192 * scale, 563.2 * scale,
        192 * scale, 576 * scale);
    path.cubicTo(192 * scale, 595.2 * scale, 204.8 * scale, 608 * scale,
        224 * scale, 608 * scale);
    path.lineTo(352 * scale, 608 * scale);
    path.cubicTo(364.8 * scale, 608 * scale, 377.6 * scale, 601.6 * scale,
        384 * scale, 588.8 * scale);
    path.lineTo(435.2 * scale, 480 * scale);
    path.lineTo(473.6 * scale, 627.2 * scale);
    path.cubicTo(480 * scale, 640 * scale, 492.8 * scale, 652.8 * scale,
        505.6 * scale, 652.8 * scale);
    path.cubicTo(518.4 * scale, 652.8 * scale, 531.2 * scale, 646.4 * scale,
        537.6 * scale, 633.6 * scale);
    path.lineTo(627.2 * scale, 352 * scale);
    path.lineTo(665.6 * scale, 480 * scale);
    path.cubicTo(672 * scale, 492.8 * scale, 684.8 * scale, 505.6 * scale,
        697.6 * scale, 505.6 * scale);
    path.lineTo(800 * scale, 505.6 * scale);
    path.cubicTo(819.2 * scale, 505.6 * scale, 832 * scale, 518.4 * scale,
        832 * scale, 537.6 * scale);
    path.cubicTo(832 * scale, 550.4 * scale, 819.2 * scale, 544 * scale,
        800 * scale, 544 * scale);
    path.close();

    // 外圆
    path.moveTo(512 * scale, 64 * scale);
    path.cubicTo(268.8 * scale, 64 * scale, 64 * scale, 268.8 * scale,
        64 * scale, 512 * scale);
    path.cubicTo(64 * scale, 755.2 * scale, 268.8 * scale, 960 * scale,
        512 * scale, 960 * scale);
    path.cubicTo(755.2 * scale, 960 * scale, 960 * scale, 755.2 * scale,
        960 * scale, 512 * scale);
    path.cubicTo(960 * scale, 268.8 * scale, 755.2 * scale, 64 * scale,
        512 * scale, 64 * scale);
    path.moveTo(512 * scale, 896 * scale);
    path.cubicTo(300.8 * scale, 896 * scale, 128 * scale, 723.2 * scale,
        128 * scale, 512 * scale);
    path.cubicTo(128 * scale, 300.8 * scale, 300.8 * scale, 128 * scale,
        512 * scale, 128 * scale);
    path.cubicTo(723.2 * scale, 128 * scale, 896 * scale, 300.8 * scale,
        896 * scale, 512 * scale);
    path.cubicTo(896 * scale, 723.2 * scale, 723.2 * scale, 896 * scale,
        512 * scale, 896 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PowerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
