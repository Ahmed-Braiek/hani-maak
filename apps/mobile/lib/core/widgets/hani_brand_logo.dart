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
      light ? HaniColors.brandWhite : HaniColors.brandBlueDeep;

  Color get _secondary =>
      light ? HaniColors.brandWhite.withValues(alpha: .90) : HaniColors.brandSky;

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
                stops: [0, .36, .72, 1],
              ))
        .createShader(bounds);

    final ribbon = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .155
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Vector recreation of the official Heni Maak ribbon/heart mark.
    // Proportions tightened against the supplied official icon variants.
    // The mark is two interlocking ribbons forming a heart / caring loop.
    final left = Path()
      ..moveTo(size.width * .53, size.height * .79)
      ..cubicTo(
        size.width * .38,
        size.height * .64,
        size.width * .08,
        size.height * .60,
        size.width * .07,
        size.height * .35,
      )
      ..cubicTo(
        size.width * .06,
        size.height * .14,
        size.width * .28,
        size.height * .10,
        size.width * .48,
        size.height * .33,
      )
      ..cubicTo(
        size.width * .64,
        size.height * .50,
        size.width * .68,
        size.height * .66,
        size.width * .53,
        size.height * .79,
      );

    final right = Path()
      ..moveTo(size.width * .48, size.height * .34)
      ..cubicTo(
        size.width * .61,
        size.height * .12,
        size.width * .83,
        size.height * .07,
        size.width * .91,
        size.height * .29,
      )
      ..cubicTo(
        size.width * .99,
        size.height * .53,
        size.width * .79,
        size.height * .81,
        size.width * .53,
        size.height * .79,
      );

    canvas.drawPath(left, ribbon);
    canvas.drawPath(right, ribbon);
  }

  @override
  bool shouldRepaint(covariant _HaniMarkPainter oldDelegate) =>
      oldDelegate.light != light;
}
