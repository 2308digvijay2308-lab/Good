import 'package:flutter/material.dart';

/// ============================================================================
///  ACTIVE STATUS NODE
/// ----------------------------------------------------------------------------
///  A green glowing node that shows the connection state of JARVIS.
///  - idle      : steady green (online)
///  - listening : animated pulsing blue
///  - thinking  : animated amber pulsing
///  - offline   : dim grey (no API key)
/// ============================================================================

enum JarvisStatus { idle, listening, thinking, offline }

class StatusIndicator extends StatefulWidget {
  const StatusIndicator({super.key, required this.status});

  final JarvisStatus status;

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _syncAnimation();
  }

  void _syncAnimation() {
    if (_animate) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.status) {
      case JarvisStatus.listening:
        return const Color(0xFF29B6F6); // blue
      case JarvisStatus.thinking:
        return const Color(0xFFFFB300); // amber
      case JarvisStatus.offline:
        return const Color(0xFF9E9E9E); // grey
      case JarvisStatus.idle:
        return const Color(0xFF00E676); // green
    }
  }

  bool get _animate =>
      widget.status == JarvisStatus.listening ||
      widget.status == JarvisStatus.thinking;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.status.name.toUpperCase(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = _animate
              ? 0.6 + (_controller.value * 0.4)
              : 0.0;
          return Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
              boxShadow: _animate
                  ? [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.55 * glow),
                        blurRadius: 10 + (6 * _controller.value),
                        spreadRadius: 2 + (3 * _controller.value),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
            ),
          );
        },
      ),
    );
  }
}
