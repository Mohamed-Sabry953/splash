import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'splash_dust.dart';
import 'splash_painter.dart';
import 'splash_timeline.dart';

/// The splash of 5L3B: the logo told as a short story (see
/// [SplashTimeline]). [onFinished] is called once, when the logo has been
/// left at rest for a moment: that is the time to move on to the app.
///
/// When the phone is set to reduce motion the logo is shown at rest, without
/// the story, and [onFinished] is called a moment later.
class L3bSplashScreen extends StatefulWidget {
  const L3bSplashScreen({
    super.key,
    required this.onFinished,
    this.haptics = true,
    this.speed = 1,
    this.backgroundColor = Colors.white,
  });

  final VoidCallback onFinished;

  /// 1 plays the splash in [SplashTimeline.total] milliseconds, 2 in half.
  final double speed;

  /// Gives a tap on the phone at each landing.
  final bool haptics;
  final Color backgroundColor;

  @override
  State<L3bSplashScreen> createState() => _L3bSplashScreenState();
}

class _L3bSplashScreenState extends State<L3bSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Set<SplashBeat> _felt = {};
  Timer? _reducedMotionTimer;
  bool _started = false;
  bool _finished = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    // The dust that the letters turn into takes a moment to make: it is made
    // before anything moves.
    SplashDust.prepare();
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(
              milliseconds: (SplashTimeline.total / widget.speed).round(),
            ),
          )
          ..addListener(_feel)
          ..addStatusListener((status) {
            // With reduced motion the controller starts at its end.
            if (status == AnimationStatus.completed && !_reducedMotion) {
              _finish();
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _reducedMotion = true;
      _controller.value = 1;
      _reducedMotionTimer = Timer(const Duration(milliseconds: 700), _finish);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _reducedMotionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  void _feel() {
    if (!widget.haptics) return;
    final ms = _controller.value * SplashTimeline.total;
    for (final (at, beat) in SplashTimeline.beats) {
      if (ms < at || !_felt.add(beat)) continue;
      final tap = switch (beat) {
        SplashBeat.thrown => HapticFeedback.lightImpact(),
        SplashBeat.kick => HapticFeedback.heavyImpact(),
        SplashBeat.home => HapticFeedback.mediumImpact(),
      };
      // Not every phone can vibrate: it is not worth an error.
      tap.catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: Semantics(
        label: '5L3B',
        image: true,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: SplashPainter(
                ms: _controller.value * SplashTimeline.total,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
