import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HaniAnimatedEntrance extends StatelessWidget {
  const HaniAnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final progress = delay.inMilliseconds == 0
            ? value
            : ((value * (420 + delay.inMilliseconds) - delay.inMilliseconds) /
                    420)
                .clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}

class HaniPageHeader extends StatelessWidget {
  const HaniPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 29,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 7),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: HaniColors.muted,
                    height: 1.45,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class HaniSectionHeader extends StatelessWidget {
  const HaniSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: HaniColors.muted,
                    fontSize: 12.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}

class HaniGradientCard extends StatelessWidget {
  const HaniGradientCard({
    super.key,
    required this.child,
    this.gradient = HaniGradients.soft,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .85)),
        boxShadow: [
          BoxShadow(
            color: HaniColors.ink.withValues(alpha: .055),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return _HaniPressable(
      onTap: onTap!,
      radius: 28,
      child: content,
    );
  }
}

class HaniMetricCard extends StatelessWidget {
  const HaniMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tint = HaniColors.primarySoft,
    this.iconColor = HaniColors.primary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: tint,
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  color: HaniColors.muted,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HaniPill extends StatelessWidget {
  const HaniPill({
    super.key,
    required this.label,
    this.icon,
    this.background = HaniColors.primarySoft,
    this.foreground = HaniColors.primaryDeep,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class HaniSettingsTile extends StatelessWidget {
  const HaniSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: HaniColors.primarySoft,
        child: Icon(icon, color: HaniColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: HaniColors.muted, fontSize: 12.5),
            ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    );
  }
}


class HaniAmbientWash extends StatefulWidget {
  const HaniAmbientWash({super.key});

  @override
  State<HaniAmbientWash> createState() => _HaniAmbientWashState();
}

class _HaniAmbientWashState extends State<HaniAmbientWash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = Curves.easeInOut.transform(_controller.value);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -120 + (v * 26),
                left: -96 + (v * 18),
                child: _GlowCircle(
                  size: 300,
                  color: HaniColors.mint.withValues(alpha: .24),
                ),
              ),
              Positioned(
                top: 250 - (v * 20),
                right: -150 + (v * 22),
                child: _GlowCircle(
                  size: 330,
                  color: HaniColors.lilac.withValues(alpha: .22),
                ),
              ),
              Positioned(
                bottom: 80 + (v * 24),
                left: -130 + (v * 16),
                child: _GlowCircle(
                  size: 270,
                  color: HaniColors.aqua.withValues(alpha: .34),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .45),
              blurRadius: 70,
              spreadRadius: 6,
            ),
          ],
        ),
      );
}

class HaniPulseMark extends StatefulWidget {
  const HaniPulseMark({
    super.key,
    this.size = 52,
    this.icon = Icons.graphic_eq_rounded,
    this.foreground = Colors.white,
    this.background = HaniColors.primary,
  });

  final double size;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  State<HaniPulseMark> createState() => _HaniPulseMarkState();
}

class _HaniPulseMarkState extends State<HaniPulseMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1850),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size * 1.34,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = Curves.easeOut.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: .78 + (progress * .42),
                child: Opacity(
                  opacity: (1 - progress) * .28,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.background,
                    ),
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.background,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.background.withValues(alpha: .24),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.foreground,
                  size: widget.size * .46,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HaniPressable extends StatefulWidget {
  const _HaniPressable({
    required this.child,
    required this.onTap,
    required this.radius,
  });

  final Widget child;
  final VoidCallback onTap;
  final double radius;

  @override
  State<_HaniPressable> createState() => _HaniPressableState();
}

class _HaniPressableState extends State<_HaniPressable> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: pressed ? .985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.radius),
            onHighlightChanged: (value) {
              if (mounted) setState(() => pressed = value);
            },
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      );
}
