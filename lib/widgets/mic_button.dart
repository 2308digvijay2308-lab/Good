import 'package:flutter/material.dart';

/// ============================================================================
///  ERGONOMIC PULSING FLOATING ACTION MIC BUTTON
/// ----------------------------------------------------------------------------
///  A circular FloatingActionButton that pulses with animated rings while
///  listening, sits above the input row, and triggers voice input.
/// ============================================================================

class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.listening,
    required this.onPressed,
  });

  final bool listening;
  final VoidCallback onPressed;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  late final Animation<double> _scale =
      Tween(begin: 0.9, end: 1.5).animate(
    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listening && !oldWidget.listening) {
      _pulse.repeat();
    } else if (!widget.listening && oldWidget.listening) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.listening ? Colors.black : Colors.white;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Expanding pulse rings while listening.
            if (widget.listening)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.35 * (1 - _pulse.value)),
                ),
                transform: Matrix4.identity()..scale(_scale.value),
              ),
            child!,
          ],
        );
      },
      child: FloatingActionButton.large(
        heroTag: 'jarvis_mic',
        onPressed: widget.onPressed,
        backgroundColor: widget.listening
            ? const Color(0xFFFF5252)
            : const Color(0xFF00E676),
        elevation: 6,
        child: Icon(
          widget.listening ? Icons.mic : Icons.mic_none,
          color: fg,
          size: 32,
        ),
      ),
    );
  }
}
