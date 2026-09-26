import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum HaniBrandVariant { horizontal, markOnly }

class HaniBrandLogo extends StatelessWidget {
  const HaniBrandLogo({
    super.key,
    this.variant = HaniBrandVariant.horizontal,
    this.light = false,
    this.height = 54,
    this.showArabic = true,
  });

  final HaniBrandVariant variant;
  final bool light;
  final double height;
  final bool showArabic;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : HaniColors.primaryDeep;
    final secondary = light ? Colors.white70 : HaniColors.primary;
    final mark = CustomPaint(
      size: Size(height, height * .78),
      painter: _HaniMarkPainter(light: light),
    );

    if (variant == HaniBrandVariant.markOnly) {
      return SizedBox(
        width: height,
        height: height,
        child: Center(child: mark),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: height * .16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showArabic)
              Text(
                'هاني معاك',
                style: TextStyle(
                  color: color,
                  fontSize: height * .34,
                  height: .95,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.2,
                ),
              ),
            SizedBox(height: height * .04),
            Text(
              'Heni maak',
              style: TextStyle(
                color: secondary,
                fontSize: height * .22,
                height: 1,
                fontWeight: FontWeight.w500,
                letterSpacing: .1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HaniMarkPainter extends CustomPainter {
  const _HaniMarkPainter({required this.light});
  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = light
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFE8F6FF)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E61C6),
              Color(0xFF199AED),
              Color(0xFF18BFF6),
            ],
          );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = Path()
      ..moveTo(size.width * .48, size.height * .74)
      ..cubicTo(
        size.width * .34,
        size.height * .58,
        size.width * .07,
        size.height * .58,
        size.width * .09,
        size.height * .34,
      )
      ..cubicTo(
        size.width * .11,
        size.height * .13,
        size.width * .34,
        size.height * .13,
        size.width * .49,
        size.height * .35,
      )
      ..cubicTo(
        size.width * .61,
        size.height * .54,
        size.width * .63,
        size.height * .65,
        size.width * .48,
        size.height * .74,
      );

    final right = Path()
      ..moveTo(size.width * .47, size.height * .35)
      ..cubicTo(
        size.width * .59,
        size.height * .13,
        size.width * .84,
        size.height * .11,
        size.width * .9,
        size.height * .31,
      )
      ..cubicTo(
        size.width * .97,
        size.height * .54,
        size.width * .74,
        size.height * .78,
        size.width * .5,
        size.height * .76,
      );

    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  @override
  bool shouldRepaint(covariant _HaniMarkPainter oldDelegate) =>
      oldDelegate.light != light;
}
