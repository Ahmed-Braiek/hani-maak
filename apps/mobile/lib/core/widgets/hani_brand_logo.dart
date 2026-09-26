import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum HaniBrandVariant {
  stacked,
  horizontal,
  markOnly,
}

class HaniBrandLogo extends StatelessWidget {
  const HaniBrandLogo({
    super.key,
    this.variant = HaniBrandVariant.horizontal,
    this.light = false,
    this.height = 54,
  });

  final HaniBrandVariant variant;
  final bool light;
  final double height;

  Color get _primary =>
      light ? Colors.white : HaniColors.brandBlueDeep;

  Color get _secondary =>
      light ? Colors.white.withValues(alpha: .88) : HaniColors.brandSky;

  @override
  Widget build(BuildContext context) {
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

    if (variant == HaniBrandVariant.stacked) {
      return SizedBox(
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height * .56,
              child: FittedBox(child: mark),
            ),
            SizedBox(height: height * .035),
            Text(
              'هاني معاك',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primary,
                fontSize: height * .205,
                height: .95,
                fontWeight: FontWeight.w700,
                letterSpacing: -.2,
              ),
            ),
            SizedBox(height: height * .025),
            Text(
              'Heni maak',
              style: TextStyle(
                color: _secondary,
                fontSize: height * .13,
                height: 1,
                fontWeight: FontWeight.w500,
                letterSpacing: .1,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: height * .14),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هاني معاك',
              style: TextStyle(
                color: _primary,
                fontSize: height * .31,
                height: .95,
                fontWeight: FontWeight.w700,
                letterSpacing: -.2,
              ),
            ),
            SizedBox(height: height * .035),
            Text(
              'Heni maak',
              style: TextStyle(
                color: _secondary,
                fontSize: height * .20,
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
    final bounds = Offset.zero & size;
    final shader = (light
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF7F7F7),
                  Color(0xFFDCDCDC),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HaniColors.brandBlueDeep,
                  HaniColors.brandBlue,
                  HaniColors.brandSky,
                  HaniColors.brandCyan,
                ],
                stops: [0, .30, .68, 1],
              ))
        .createShader(bounds);

    final ribbon = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .145
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Vector recreation of the official Heni Maak ribbon/heart mark.
    final left = Path()
      ..moveTo(size.width * .52, size.height * .78)
      ..cubicTo(
        size.width * .36,
        size.height * .63,
        size.width * .07,
        size.height * .59,
        size.width * .08,
        size.height * .34,
      )
      ..cubicTo(
        size.width * .09,
        size.height * .13,
        size.width * .31,
        size.height * .11,
        size.width * .50,
        size.height * .34,
      )
      ..cubicTo(
        size.width * .64,
        size.height * .51,
        size.width * .66,
        size.height * .66,
        size.width * .52,
        size.height * .78,
      );

    final right = Path()
      ..moveTo(size.width * .49, size.height * .35)
      ..cubicTo(
        size.width * .61,
        size.height * .13,
        size.width * .84,
        size.height * .07,
        size.width * .91,
        size.height * .30,
      )
      ..cubicTo(
        size.width * .99,
        size.height * .55,
        size.width * .78,
        size.height * .81,
        size.width * .52,
        size.height * .78,
      );

    canvas.drawPath(left, ribbon);
    canvas.drawPath(right, ribbon);
  }

  @override
  bool shouldRepaint(covariant _HaniMarkPainter oldDelegate) =>
      oldDelegate.light != light;
}
