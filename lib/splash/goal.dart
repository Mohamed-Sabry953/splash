import 'dart:math' as math;
import 'dart:ui';

import 'scene.dart';

/// The goal, seen from the side: the front post, the roof, the post at the
/// back that leans out, and the net between them, which ripples when a ball
/// hits it.
class GoalPainter {
  GoalPainter({this.hit = Scene.netHit});

  /// Where the ball hits the net.
  final Offset hit;

  static const Color _frame = Color(0xFF0A2B60);
  static const Color _net = Color(0xFF9FB2D1);

  static double get _top => Scene.ground - Scene.goalHeight;

  /// How far the net is pushed out [ms] after the ball hit it, at [p]: a
  /// wave that is biggest where the ball hit, grows towards the back, and
  /// fades as it swings to and fro.
  static double push(Offset p, Offset hit, double ms) {
    if (ms < 0) return 0;
    final depth =
        ((p.dx - Scene.goalFront) / (Scene.goalBack - Scene.goalFront)).clamp(
          0.0,
          1.2,
        );
    final near = math.exp(-math.pow((p.dy - hit.dy) / 46, 2));
    final swing = math.exp(-ms / 250) * math.cos(ms * 0.021);
    return 17 * near * math.pow(depth, 1.3) * swing;
  }

  /// The net is not a flat thing: it is drawn as lines made of a few pieces
  /// each, so that it bends where it is pushed.
  Offset _bent(Offset p, double ms) => p + Offset(push(p, hit, ms), 0);

  /// Paints the goal. [ms] is the time since the ball hit the net (negative
  /// before); [alpha] fades the goal in and out.
  void paint(Canvas canvas, {required double ms, double alpha = 1}) {
    if (alpha <= 0) return;
    final ground = Scene.ground;
    final top = _top;
    const front = Scene.goalFront;
    const back = Scene.goalBack;
    const lean = Scene.goalLean;

    // The net: lines from the front to the back, and from the roof down.
    final net = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = _net.withValues(alpha: 0.85 * alpha);
    const rows = 6;
    for (var i = 1; i < rows; i++) {
      final y = top + (ground - top) * i / rows;
      final backX = back + lean * (y - top) / (ground - top);
      _polyline(canvas, net, Offset(front, y), Offset(backX, y), ms);
    }
    const columns = 7;
    for (var i = 1; i <= columns; i++) {
      final f = i / columns;
      _polyline(
        canvas,
        net,
        Offset(front + (back - front) * f, top),
        Offset(front + (back + lean - front) * f, ground),
        ms,
      );
    }

    // The frame, on top of the net.
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = _frame.withValues(alpha: alpha);
    frame.strokeWidth = 4.6;
    canvas.drawLine(Offset(front, ground), Offset(front, top), frame);
    canvas.drawLine(Offset(front, top), Offset(back, top), frame);
    frame.strokeWidth = 2.4;
    _polyline(
      canvas,
      frame,
      Offset(back, top),
      Offset(back + lean, ground),
      ms,
    );
  }

  /// A line from [a] to [b] that bends where the net is pushed.
  void _polyline(Canvas canvas, Paint paint, Offset a, Offset b, double ms) {
    const pieces = 9;
    final path = Path();
    for (var i = 0; i <= pieces; i++) {
      final p = _bent(Offset.lerp(a, b, i / pieces)!, ms);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }
}
