import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class RgbBorderCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Duration duration;
  final List<Color> colors;
  final bool glow;
  final bool intense;
  final List<String> glyphs;

  const RgbBorderCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.borderWidth = 2.4,
    this.duration = const Duration(seconds: 3),
    this.glow = true,
    this.intense = false,
    this.glyphs = const ['✦', '◆', '●', '■', '▲', '★'],
    this.colors = const [
      Color(0xFFFF3B6B),
      Color(0xFFFFC93B),
      Color(0xFF3BFFB0),
      Color(0xFF3BB0FF),
      Color(0xFFC23BFF),
      Color(0xFFFF3B6B),
    ],
  });

  @override
  State<RgbBorderCard> createState() => _RgbBorderCardState();
}

class _RgbBorderCardState extends State<RgbBorderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get _effectiveDuration {
    if (!widget.intense) {
      return widget.duration;
    }

    final int milliseconds = (widget.duration.inMilliseconds * 0.55).round();

    return Duration(milliseconds: math.max(1, milliseconds));
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _effectiveDuration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant RgbBorderCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final Duration newDuration = _effectiveDuration;

    if (_controller.duration != newDuration) {
      _controller.duration = newDuration;

      _controller
        ..stop()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double borderWidth = widget.intense
        ? widget.borderWidth * 1.7
        : widget.borderWidth;

    final double outerRadius = widget.borderRadius + borderWidth;

    final Color glowColor = widget.colors.isNotEmpty
        ? widget.colors[(widget.colors.length / 2).floor()]
        : Colors.blue;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double angle = _controller.value * 2 * math.pi;

        final List<Color> gradientColors = widget.colors.isNotEmpty
            ? widget.colors
            : const [Colors.blue, Colors.purple, Colors.blue];

        return Container(
          padding: EdgeInsets.all(borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
            gradient: SweepGradient(
              colors: gradientColors,
              transform: GradientRotation(angle),
            ),
            boxShadow: widget.glow
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(
                        widget.intense ? 0.60 : 0.35,
                      ),
                      blurRadius: widget.intense ? 28 : 16,
                      spreadRadius: widget.intense ? 2 : 0.5,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,

              if (widget.intense &&
                  widget.glyphs.isNotEmpty &&
                  widget.colors.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _GlyphOrbitPainter(
                        progress: _controller.value,
                        radius: widget.borderRadius,
                        glyphs: widget.glyphs,
                        colors: widget.colors,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GlyphOrbitPainter extends CustomPainter {
  final double progress;
  final double radius;
  final List<String> glyphs;
  final List<Color> colors;

  const _GlyphOrbitPainter({
    required this.progress,
    required this.radius,
    required this.glyphs,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    if (glyphs.isEmpty || colors.isEmpty) {
      return;
    }

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);

    // IMPORTANT:
    // These types belong to dart:ui.
    final ui.PathMetrics metrics = path.computeMetrics();

    // PathMetrics is a lazy iterable — calling isEmpty() consumes the first
    // element, so we must iterate rather than call .isEmpty + .first separately.
    ui.PathMetric? metric;
    for (final m in metrics) {
      metric = m;
      break;
    }
    if (metric == null) return;

    final double totalLength = metric.length;

    if (totalLength <= 0) {
      return;
    }

    for (int i = 0; i < glyphs.length; i++) {
      final double base = i / glyphs.length;

      final double offset = ((base + progress) % 1.0) * totalLength;

      final ui.Tangent? tangent = metric.getTangentForOffset(offset);

      if (tangent == null) {
        continue;
      }

      final String glyph = glyphs[i % glyphs.length];

      final Color color = colors[i % colors.length];

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color.withOpacity(0.85), blurRadius: 6)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset position =
          tangent.position -
          Offset(textPainter.width / 2, textPainter.height / 2);

      textPainter.paint(canvas, position);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.radius != radius ||
        oldDelegate.glyphs != glyphs ||
        oldDelegate.colors != colors;
  }
}
