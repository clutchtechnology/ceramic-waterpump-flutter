import 'package:flutter/material.dart';

/// 压力图标 (压力表)
class PressureIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PressureIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PressurePainter(color: color),
    );
  }
}

class _PressurePainter extends CustomPainter {
  final Color color;

  _PressurePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1024;

    final path = Path();

    // 外圆环
    path.moveTo(512.7 * scale, 42.8 * scale);
    path.lineTo(512.7 * scale, 101.3 * scale);
    path.cubicTo(533.9 * scale, 101.3 * scale, 555.4 * scale, 103 * scale,
        576.5 * scale, 106.2 * scale);
    path.cubicTo(686.2 * scale, 123.1 * scale, 782.7 * scale, 181.7 * scale,
        848.3 * scale, 271.2 * scale);
    path.cubicTo(913.9 * scale, 360.7 * scale, 940.7 * scale, 470.4 * scale,
        923.8 * scale, 580.1 * scale);
    path.cubicTo(892.8 * scale, 780.9 * scale, 716.6 * scale, 932.3 * scale,
        513.8 * scale, 932.3 * scale);
    path.cubicTo(492.6 * scale, 932.3 * scale, 471.1 * scale, 930.6 * scale,
        449.9 * scale, 927.4 * scale);
    path.cubicTo(223.5 * scale, 892.4 * scale, 67.7 * scale, 679.9 * scale,
        102.6 * scale, 453.4 * scale);
    path.cubicTo(133.6 * scale, 252.6 * scale, 309.8 * scale, 101.2 * scale,
        512.6 * scale, 101.2 * scale);
    path.lineTo(512.7 * scale, 42.8 * scale);

    path.moveTo(512.6 * scale, 42.8 * scale);
    path.cubicTo(282.7 * scale, 42.8 * scale, 80.9 * scale, 210.4 * scale,
        44.8 * scale, 444.6 * scale);
    path.cubicTo(5 * scale, 703.2 * scale, 182.3 * scale, 945.2 * scale,
        441 * scale, 985.1 * scale);
    path.cubicTo(465.5 * scale, 988.9 * scale, 489.8 * scale, 990.7 * scale,
        513.8 * scale, 990.7 * scale);
    path.cubicTo(743.7 * scale, 990.7 * scale, 945.5 * scale, 823.1 * scale,
        981.6 * scale, 588.9 * scale);
    path.cubicTo(1021.5 * scale, 330.2 * scale, 844.1 * scale, 88.2 * scale,
        585.4 * scale, 48.3 * scale);
    path.cubicTo(560.9 * scale, 44.6 * scale, 536.6 * scale, 42.8 * scale,
        512.6 * scale, 42.8 * scale);
    path.close();

    // 内部弧线1
    path.moveTo(811.4 * scale, 571 * scale);
    path.cubicTo(810.3 * scale, 571 * scale, 809.2 * scale, 570.9 * scale,
        808.1 * scale, 570.8 * scale);
    path.cubicTo(792.1 * scale, 569 * scale, 780.5 * scale, 554.5 * scale,
        782.3 * scale, 538.5 * scale);
    path.cubicTo(798.2 * scale, 397.3 * scale, 700.5 * scale, 269.7 * scale,
        560 * scale, 248 * scale);
    path.cubicTo(524.8 * scale, 242.6 * scale, 500.2 * scale, 242.8 * scale,
        472.3 * scale, 248.9 * scale);
    path.cubicTo(456.5 * scale, 252.4 * scale, 441 * scale, 242.3 * scale,
        437.5 * scale, 226.6 * scale);
    path.cubicTo(434 * scale, 210.9 * scale, 444.1 * scale, 195.3 * scale,
        459.8 * scale, 191.8 * scale);
    path.cubicTo(494.9 * scale, 184.1 * scale, 526.5 * scale, 183.7 * scale,
        568.9 * scale, 190.2 * scale);
    path.cubicTo(740.6 * scale, 216.7 * scale, 859.9 * scale, 372.5 * scale,
        840.5 * scale, 545 * scale);
    path.cubicTo(838.8 * scale, 560 * scale, 826.1 * scale, 571 * scale,
        811.4 * scale, 571 * scale);
    path.close();

    // 内部弧线2
    path.moveTo(203.4 * scale, 558.1 * scale);
    path.cubicTo(187.2 * scale, 558.1 * scale, 174.1 * scale, 545 * scale,
        174.2 * scale, 528.8 * scale);
    path.cubicTo(174.2 * scale, 514 * scale, 175.3 * scale, 483.6 * scale,
        178.2 * scale, 465.1 * scale);
    path.cubicTo(191.4 * scale, 379.7 * scale, 229.1 * scale, 310.7 * scale,
        290.3 * scale, 259.9 * scale);
    path.cubicTo(302.7 * scale, 249.6 * scale, 321.2 * scale, 251.3 * scale,
        331.5 * scale, 263.8 * scale);
    path.cubicTo(341.8 * scale, 276.2 * scale, 340.1 * scale, 294.7 * scale,
        327.6 * scale, 305 * scale);
    path.cubicTo(277.7 * scale, 346.3 * scale, 246.9 * scale, 403.2 * scale,
        236 * scale, 474.1 * scale);
    path.cubicTo(234 * scale, 487.1 * scale, 232.7 * scale, 512.7 * scale,
        232.7 * scale, 529 * scale);
    path.cubicTo(232.6 * scale, 545 * scale, 219.5 * scale, 558.1 * scale,
        203.4 * scale, 558.1 * scale);
    path.close();

    // 中心圆点
    path.moveTo(513.1 * scale, 489.8 * scale);
    path.cubicTo(514.5 * scale, 489.8 * scale, 515.9 * scale, 489.9 * scale,
        517.3 * scale, 490.1 * scale);
    path.cubicTo(526.9 * scale, 491.6 * scale, 532.4 * scale, 497.4 * scale,
        534.9 * scale, 500.8 * scale);
    path.cubicTo(537.4 * scale, 504.2 * scale, 541.3 * scale, 511.2 * scale,
        539.8 * scale, 520.8 * scale);
    path.cubicTo(537.8 * scale, 533.8 * scale, 526.4 * scale, 543.6 * scale,
        513.3 * scale, 543.6 * scale);
    path.cubicTo(511.9 * scale, 543.6 * scale, 510.5 * scale, 543.5 * scale,
        509.1 * scale, 543.3 * scale);
    path.cubicTo(494.4 * scale, 541 * scale, 484.4 * scale, 527.3 * scale,
        486.6 * scale, 512.6 * scale);
    path.cubicTo(488.6 * scale, 499.6 * scale, 500 * scale, 489.8 * scale,
        513.1 * scale, 489.8 * scale);

    path.moveTo(513.1 * scale, 431.4 * scale);
    path.cubicTo(471.7 * scale, 431.4 * scale, 435.4 * scale, 461.6 * scale,
        428.8 * scale, 503.8 * scale);
    path.cubicTo(421.6 * scale, 550.4 * scale, 453.6 * scale, 594 * scale,
        500.2 * scale, 601.2 * scale);
    path.cubicTo(504.6 * scale, 601.9 * scale, 509 * scale, 602.2 * scale,
        513.3 * scale, 602.2 * scale);
    path.cubicTo(554.7 * scale, 602.2 * scale, 591 * scale, 572 * scale,
        597.6 * scale, 529.8 * scale);
    path.cubicTo(604.8 * scale, 483.2 * scale, 572.8 * scale, 439.6 * scale,
        526.2 * scale, 432.4 * scale);
    path.cubicTo(521.8 * scale, 431.7 * scale, 517.4 * scale, 431.4 * scale,
        513.1 * scale, 431.4 * scale);
    path.close();

    // 指针
    path.moveTo(472.2 * scale, 464.7 * scale);
    path.cubicTo(461.2 * scale, 464.7 * scale, 450.7 * scale, 458.5 * scale,
        445.7 * scale, 447.8 * scale);
    path.lineTo(357 * scale, 257.9 * scale);
    path.cubicTo(350.2 * scale, 243.3 * scale, 356.5 * scale, 225.9 * scale,
        371.1 * scale, 219 * scale);
    path.cubicTo(385.7 * scale, 212.2 * scale, 403.2 * scale, 218.5 * scale,
        410 * scale, 233.1 * scale);
    path.lineTo(498.7 * scale, 423 * scale);
    path.cubicTo(505.5 * scale, 437.6 * scale, 499.2 * scale, 455 * scale,
        484.6 * scale, 461.9 * scale);
    path.cubicTo(480.6 * scale, 463.8 * scale, 476.4 * scale, 464.7 * scale,
        472.2 * scale, 464.7 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PressurePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
