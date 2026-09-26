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
            colors: [
              Colors.white,
              Color(0xFFF2F2F2),
              Color(0xFFD8D8D8),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HaniColors.brandBlueDeep,
              HaniColors.brandSky,
              HaniColors.brandCyan,
            ],
          );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .145
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = Path()
      ..moveTo(size.width * .48, size.height * .75)
      ..cubicTo(
        size.width * .31,
        size.height * .62,
        size.width * .06,
        size.height * .59,
        size.width * .08,
        size.height * .34,
      )
      ..cubicTo(
        size.width * .10,
        size.height * .13,
        size.width * .32,
        size.height * .11,
        size.width * .49,
        size.height * .34,
      )
      ..cubicTo(
        size.width * .61,
        size.height * .50,
        size.width * .63,
        size.height * .66,
        size.width * .48,
        size.height * .75,
      );

    final right = Path()
      ..moveTo(size.width * .47, size.height * .35)
      ..cubicTo(
        size.width * .60,
        size.height * .12,
        size.width * .84,
        size.height * .08,
        size.width * .91,
        size.height * .30,
      )
      ..cubicTo(
        size.width * .99,
        size.height * .55,
        size.width * .76,
        size.height * .80,
        size.width * .50,
        size.height * .76,
      );

    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  @override
  bool shouldRepaint(covariant _HaniMarkPainter oldDelegate) =>
      oldDelegate.light != light;
}
