import 'dart:ui';

import 'scene.dart';

/// The goal, seen from the side: the front post, the bar over it, and the
/// post at the back that leans out. It has no net: the ball goes through it.
class GoalPainter {
  const GoalPainter();

  static const Color _frame = Color(0xFF0A2B60);

  /// Paints the goal. [alpha] fades it in and out.
  void paint(Canvas canvas, {double alpha = 1}) {
    if (alpha <= 0) return;
    const ground = Scene.ground;
    const top = Scene.ground - Scene.goalHeight;
    const front = Scene.goalFront;
    const back = Scene.goalBack;
    const lean = Scene.goalLean;

    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _frame.withValues(alpha: alpha);
    // The post in front and the bar: one line that turns.
    frame.strokeWidth = 5;
    canvas.drawPath(
      Path()
        ..moveTo(front, ground)
        ..lineTo(front, top)
        ..lineTo(back, top),
      frame,
    );
    // The post at the back, thinner, as it is farther.
    frame.strokeWidth = 3;
    canvas.drawLine(
      Offset(back, top),
      const Offset(back + lean, ground),
      frame,
    );
  }
}
