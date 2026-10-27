import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'l3b_logo.dart';
import 'logo_data.dart';
import 'splash_timeline.dart';

/// Where the logo sits on a screen.
class SplashLayout {
  const SplashLayout(this.scale, this.origin);

  factory SplashLayout.of(Size size) {
    final width = math.min(size.width * 0.84, 540.0);
    final scale = width / kLogoWidth;
    final height = kLogoHeight * scale;
    return SplashLayout(
      scale,
      Offset((size.width - width) / 2, size.height * 0.46 - height / 2),
    );
  }

  /// Screen pixels in one unit of the logo.
  final double scale;

  /// Where the top left of the logo is.
  final Offset origin;

  Offset toScreen(Offset logoPoint) => origin + logoPoint * scale;
}

/// Paints the splash at [ms] milliseconds after its start. It only depends on
/// the time, so any moment can be painted on its own.
class SplashPainter extends CustomPainter {
  const SplashPainter({required this.ms});

  final double ms;

  static const Color navy = Color(0xFF0A2B60);
  static const Color blue = Color(0xFF054FBA);
  static const Color green = Color(0xFF8DC641);
  static const Color _line = Color(0xFFD9E3F2);

  static const Curve _fiveCurve = Cubic(0.22, 1.5, 0.36, 1);
  static const Curve _letterCurve = Cubic(0.2, 1.25, 0.4, 1);
  static const Curve _swooshCurve = Cubic(0.16, 1, 0.3, 1);

  /// Where the stroke out of the 5 starts to be its own piece.
  static const double _seamX = 314;

  static final List<_Shard> _fiveShards = _Shard.burst(
    seed: 11,
    count: 14,
    from: -math.pi,
    to: math.pi,
  );
  static final List<_Shard> _ballShardsLeft = _Shard.burst(
    seed: 5,
    count: 5,
    from: -math.pi * 0.97,
    to: -math.pi * 0.58,
    slower: 0.85,
  );
  static final List<_Shard> _ballShardsRight = _Shard.burst(
    seed: 8,
    count: 5,
    from: -math.pi * 0.42,
    to: -math.pi * 0.03,
    slower: 0.85,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final logo = L3bLogo.instance;
    final layout = SplashLayout.of(size);
    final scale = layout.scale;
    final scene = _Scene(canvas, logo, layout, ms);

    scene.groundLine(size);
    scene.pulses(size);

    canvas.save();
    final shake = scene.shake();
    canvas.translate(layout.origin.dx + shake.dx, layout.origin.dy + shake.dy);
    canvas.scale(scale);

    scene.rings();
    scene.shadow();

    final shining =
        ms > SplashTimeline.shineStart && ms < SplashTimeline.shineEnd;
    if (shining) {
      // The shine only touches what the logo is made of: it is painted over
      // the logo in a layer of its own.
      canvas.saveLayer(
        const Rect.fromLTWH(-60, -80, kLogoWidth + 120, kLogoHeight + 160),
        Paint(),
      );
    }
    scene.ball();
    scene.five();
    scene.swoosh();
    scene.letters();
    if (shining) {
      scene.shine();
      canvas.restore();
    }

    scene.shards(_fiveShards, SplashTimeline.fiveImpact, logo.five.center);
    scene.shards(
      _ballShardsLeft,
      SplashTimeline.ballLand,
      const Offset(kBallCx - kBallRadius * 0.8, L3bLogo.ballBottom),
      floor: L3bLogo.ballBottom,
    );
    scene.shards(
      _ballShardsRight,
      SplashTimeline.ballLand,
      const Offset(kBallCx + kBallRadius * 0.8, L3bLogo.ballBottom),
      floor: L3bLogo.ballBottom,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashPainter oldDelegate) => oldDelegate.ms != ms;
}

/// How the ball is, in logo units.
class _BallPose {
  const _BallPose({
    required this.dx,
    required this.hop,
    required this.sx,
    required this.sy,
    required this.tilt,
  });

  /// How far it is from its place, to the right.
  final double dx;

  /// How high it is above the ground.
  final double hop;

  /// Squashed when it hits the ground, stretched when it flies fast.
  final double sx;
  final double sy;
  final double tilt;
}

/// A little pentagon, like a patch of the ball, thrown out by an impact.
class _Shard {
  const _Shard({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.life,
    required this.color,
    required this.turn,
  });

  static List<_Shard> burst({
    required int seed,
    required int count,
    required double from,
    required double to,
    double slower = 1,
  }) {
    final random = math.Random(seed);
    const colors = [
      SplashPainter.navy,
      SplashPainter.blue,
      SplashPainter.green,
      SplashPainter.green,
      SplashPainter.blue,
    ];
    return [
      for (var i = 0; i < count; i++)
        _Shard(
          angle: from + (to - from) * ((i + random.nextDouble() * 0.7) / count),
          speed: (620 + random.nextDouble() * 620) * slower,
          spin: (random.nextDouble() - 0.5) * 16,
          size: 11 + random.nextDouble() * 13,
          life: 620 + random.nextDouble() * 320,
          color: colors[i % colors.length],
          turn: random.nextDouble() * math.pi,
        ),
    ];
  }

  final double angle;

  /// Logo units per second.
  final double speed;
  final double spin;
  final double size;

  /// Milliseconds before it is gone.
  final double life;
  final Color color;
  final double turn;
}

/// One frame: every layer of the splash at [ms], painted on [canvas].
class _Scene {
  _Scene(this.canvas, this.logo, this.layout, this.ms);

  final Canvas canvas;
  final L3bLogo logo;
  final SplashLayout layout;
  final double ms;

  final Paint _paint = Paint();

  // --- the ball -----------------------------------------------------------

  /// Where the ball is as the splash begins: out of sight on the left, even
  /// when it is stretched.
  double get _startDx =>
      -(layout.origin.dx / layout.scale) - (kBallCx + kBallRadius) - 100;

  double _hopAt(double t) {
    for (var i = 0; i < SplashTimeline.hopStarts.length; i++) {
      final a = SplashTimeline.hopStarts[i];
      final b = SplashTimeline.hopEnds[i];
      if (t >= a && t < b) {
        final u = (t - a) / (b - a);
        return SplashTimeline.hopHeights[i] * 4 * u * (1 - u);
      }
    }
    return 0;
  }

  double _squashAt(double t) {
    var squash = 0.0;
    for (var i = 0; i < SplashTimeline.hopEnds.length; i++) {
      final d = t - SplashTimeline.hopEnds[i];
      // Quick to squash, slower to get round again.
      final w = d < 0 ? 26.0 : 70.0;
      squash += SplashTimeline.hopSquash[i] * math.exp(-(d / w) * (d / w));
    }
    return squash;
  }

  _BallPose _ballPose(double t) {
    final p = seg(t, SplashTimeline.ballStart, SplashTimeline.ballLand);
    final e = Curves.easeOutCubic.transform(p);
    final fast = math.pow(1 - p, 2).toDouble();
    final squash = _squashAt(t);
    return _BallPose(
      dx: _startDx * (1 - e),
      hop: _hopAt(t),
      sx: 1 + 0.8 * squash + 0.16 * fast,
      sy: 1 - squash - 0.06 * fast,
      tilt: 0.10 * fast,
    );
  }

  void _drawBall(_BallPose pose, double alpha) {
    canvas.save();
    // Squash and stretch hold the ball to the ground it stands on.
    canvas.translate(kBallCx + pose.dx, L3bLogo.ballBottom - pose.hop);
    canvas.scale(pose.sx, pose.sy);
    canvas.translate(-kBallCx, -L3bLogo.ballBottom);
    canvas.translate(kBallCx, kBallCy);
    canvas.rotate(pose.tilt);
    canvas.translate(-kBallCx, -kBallCy);
    // The piece the 5 will cover is there until the 5 lands.
    _fill(
      logo.ballFill,
      alpha *
          (1 -
              seg(
                ms,
                SplashTimeline.fiveImpact + 5,
                SplashTimeline.fiveImpact + 45,
              )),
    );
    for (final piece in logo.ball) {
      _fill(piece, alpha);
    }
    canvas.restore();
  }

  void ball() {
    // A few copies left behind show how fast it comes.
    final p = seg(ms, SplashTimeline.ballStart, SplashTimeline.ballLand);
    final trail = ((1 - p) * 2.2).clamp(0.0, 1.0);
    const ghosts = [0.20, 0.12, 0.06];
    if (trail > 0) {
      for (var i = ghosts.length; i >= 1; i--) {
        final t = ms - 34.0 * i;
        if (t < SplashTimeline.ballStart) continue;
        _drawBall(_ballPose(t), ghosts[i - 1] * trail);
      }
    }
    _drawBall(_ballPose(ms), 1);
  }

  /// The shadow on the ground: small and dark when the ball is down.
  void shadow() {
    final fade = 1 - seg(ms, 1300, 1750);
    if (fade <= 0) return;
    final pose = _ballPose(ms);
    final high = (pose.hop / SplashTimeline.hopHeights.first).clamp(0.0, 1.0);
    final rx = kBallRadius * (0.95 - 0.35 * high);
    _paint
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..color = SplashPainter.navy.withValues(
        alpha: 0.20 * (1 - 0.7 * high) * fade,
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(kBallCx + pose.dx, L3bLogo.ballBottom + 3),
        width: rx * 2,
        height: rx * 0.26,
      ),
      _paint,
    );
    _paint.maskFilter = null;
  }

  // --- the 5 --------------------------------------------------------------

  void five() {
    final q = seg(ms, SplashTimeline.fiveStart, SplashTimeline.fiveEnd);
    if (ms < SplashTimeline.fiveStart) return;
    final c = SplashPainter._fiveCurve.transform(q);
    final alpha = seg(
      ms,
      SplashTimeline.fiveStart,
      SplashTimeline.fiveStart + 40,
    );
    final center = logo.five.center;
    canvas.save();
    // It falls from above, big, and is pressed into the gap the ball left.
    canvas.translate(center.dx, center.dy - 240 * (1 - c));
    canvas.scale(1 + 0.5 * (1 - c));
    canvas.translate(-center.dx, -center.dy);
    _fill(logo.five, alpha);
    canvas.restore();
  }

  // --- the stroke ---------------------------------------------------------

  void swoosh() {
    if (ms < SplashTimeline.swooshStart) return;
    final w = seg(
      ms,
      SplashTimeline.swooshStart,
      SplashTimeline.swooshEnd,
      SplashPainter._swooshCurve,
    );
    final tipX = lerpDouble(SplashPainter._seamX - 4, kLogoWidth + 30, w)!;

    // The stroke is drawn from the 5 to the right, as if it was thrown.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, -60, tipX, kLogoHeight + 20));
    _fill(logo.swoosh, 1);
    canvas.restore();

    _speedLines();
    _tipGlow(tipX, w);
  }

  void _tipGlow(double tipX, double w) {
    final fade = 1 - seg(w, 0.82, 1);
    if (fade <= 0 || w <= 0) return;
    final x = math.min(tipX, kLogoWidth - 8);
    final y = logo.swooshMiddleAt(x);
    final radius = lerpDouble(34, 18, w)!;
    final rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
    _paint
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFDDF5A8).withValues(alpha: 0.95 * fade),
          SplashPainter.green.withValues(alpha: 0.45 * fade),
          SplashPainter.green.withValues(alpha: 0),
        ],
        stops: const [0, 0.38, 1],
      ).createShader(rect);
    canvas.drawCircle(rect.center, radius, _paint);
    _paint.shader = null;
  }

  /// Thin lines rushing to the right above the stroke.
  void _speedLines() {
    const lines = [
      (y: 50.0, length: 210.0, delay: 0.0),
      (y: 72.0, length: 150.0, delay: 45.0),
      (y: 30.0, length: 120.0, delay: 85.0),
    ];
    for (final line in lines) {
      final w = seg(
        ms,
        SplashTimeline.swooshStart + line.delay,
        SplashTimeline.swooshStart + line.delay + 400,
        Curves.easeOutCubic,
      );
      if (w <= 0 || w >= 1) continue;
      final head = lerpDouble(330, kLogoWidth + 260, w)!;
      final tail = head - line.length * (1 - 0.5 * w);
      final a = 0.55 * math.pow(1 - w, 0.8).toDouble();
      _paint
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.4
        ..shader = LinearGradient(
          colors: [
            SplashPainter.green.withValues(alpha: 0),
            SplashPainter.green.withValues(alpha: a),
          ],
        ).createShader(Rect.fromLTRB(tail, line.y - 1, head, line.y + 1));
      canvas.drawLine(Offset(tail, line.y), Offset(head, line.y), _paint);
    }
    _paint
      ..shader = null
      ..style = PaintingStyle.fill;
  }

  // --- the letters --------------------------------------------------------

  void letters() {
    for (var i = 0; i < logo.letters.length; i++) {
      final start = SplashTimeline.lettersStart + i * SplashTimeline.letterGap;
      final q = seg(ms, start, start + SplashTimeline.letterTime);
      if (ms < start) continue;
      final piece = logo.letters[i];
      final alpha = (q * 3.4).clamp(0.0, 1.0);

      // Two faint copies behind it make the slide look fast.
      const ghosts = [0.20, 0.10];
      if (q < 1) {
        for (var j = ghosts.length; j >= 1; j--) {
          final qj = (q - 0.075 * j).clamp(0.0, 1.0);
          _drawLetter(piece, qj, ghosts[j - 1] * (1 - q) * alpha);
        }
      }
      _drawLetter(piece, q, alpha);
    }
  }

  void _drawLetter(LogoPiece piece, double q, double alpha) {
    final e = SplashPainter._letterCurve.transform(q);
    final pivot = Offset(piece.bounds.center.dx, piece.bounds.bottom);
    canvas.save();
    canvas.translate(190 * (1 - e), 0);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.transform(Matrix4.skewX(-0.28 * (1 - e)).storage);
    canvas.translate(-pivot.dx, -pivot.dy);
    _fill(piece, alpha);
    canvas.restore();
  }

  // --- shine --------------------------------------------------------------

  void shine() {
    final w = seg(
      ms,
      SplashTimeline.shineStart,
      SplashTimeline.shineEnd,
      Curves.easeInOutCubic,
    );
    const width = 170.0;
    const lean = 110.0; // as slanted as the letters
    final x = lerpDouble(-width - lean, kLogoWidth + 40, w)!;
    final band = Path()
      ..moveTo(x + lean, -40)
      ..lineTo(x + lean + width, -40)
      ..lineTo(x + width, kLogoHeight + 40)
      ..lineTo(x, kLogoHeight + 40)
      ..close();
    _paint
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcATop
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.72),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(x, 0, x + lean + width, 1));
    canvas.drawPath(band, _paint);
    _paint
      ..shader = null
      ..blendMode = BlendMode.srcOver;
  }

  // --- impacts ------------------------------------------------------------

  /// Rings that spread from the places where something landed.
  void rings() {
    // The ball on the ground: flat rings, as seen from the side.
    for (final (delay, color, alpha) in [
      (0.0, SplashPainter.blue, 0.34),
      (90.0, SplashPainter.green, 0.38),
    ]) {
      final e = seg(
        ms,
        SplashTimeline.ballLand + delay,
        SplashTimeline.ballLand + delay + 700,
        Curves.easeOutCubic,
      );
      if (e <= 0 || e >= 1) continue;
      final rx = kBallRadius * (0.9 + 2.0 * e);
      _ring(
        Rect.fromCenter(
          center: const Offset(kBallCx, L3bLogo.ballBottom + 3),
          width: rx * 2,
          height: rx * 0.34,
        ),
        color.withValues(alpha: alpha * math.pow(1 - e, 1.3).toDouble()),
        6 * (1 - e) + 1.2,
      );
    }

    // The 5 pressed into its place: a round one.
    final e = seg(
      ms,
      SplashTimeline.fiveImpact,
      SplashTimeline.fiveImpact + 650,
      Curves.easeOutCubic,
    );
    if (e > 0 && e < 1) {
      final radius = 70 + 330 * e;
      _ring(
        Rect.fromCircle(center: logo.five.center, radius: radius),
        SplashPainter.green.withValues(
          alpha: 0.40 * math.pow(1 - e, 1.3).toDouble(),
        ),
        7 * (1 - e) + 1.2,
      );
    }
  }

  void _ring(Rect rect, Color color, double width) {
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    canvas.drawOval(rect, _paint);
    _paint.style = PaintingStyle.fill;
  }

  static const double _gravity = 2400; // logo units per second, squared

  /// Shards thrown from [origin] at [at]. With [floor] they bounce on the
  /// ground instead of falling through it.
  void shards(List<_Shard> shards, double at, Offset origin, {double? floor}) {
    final age = ms - at;
    if (age <= 0) return;
    for (final shard in shards) {
      if (age >= shard.life) continue;
      final s = age / 1000;
      final life = age / shard.life;
      final x = origin.dx + math.cos(shard.angle) * shard.speed * s;
      final vy = math.sin(shard.angle) * shard.speed;
      final y = floor == null
          ? origin.dy + vy * s + 0.5 * _gravity * s * s
          : _fallOnto(floor, origin.dy, vy, s);
      final alpha = math.pow(1 - life, 1.4).toDouble();
      final size = shard.size * (1 - 0.4 * life);
      final turn = shard.turn + shard.spin * s;
      final path = Path();
      for (var i = 0; i < 5; i++) {
        final a = turn + i * 2 * math.pi / 5;
        final p = Offset(x + math.cos(a) * size, y + math.sin(a) * size);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        _paint..color = shard.color.withValues(alpha: alpha),
      );
    }
  }

  /// Height of something thrown at [vy] (negative is up) from [y0] after [t]
  /// seconds, that loses most of its speed each time it hits [floor].
  double _fallOnto(double floor, double y0, double vy, double t) {
    var y = y0;
    var v = vy;
    for (var i = 0; i < 4; i++) {
      final reach =
          (-v + math.sqrt(v * v + 2 * _gravity * (floor - y))) / _gravity;
      if (t <= reach) return y + v * t + 0.5 * _gravity * t * t;
      v = -(v + _gravity * reach) * 0.38;
      y = floor;
      t -= reach;
    }
    return floor;
  }

  /// The logo shakes a little when something lands on it (screen pixels).
  Offset shake() {
    var dx = 0.0;
    var dy = 0.0;
    for (final (at, amp) in [
      (SplashTimeline.ballLand, 4.0),
      (SplashTimeline.fiveImpact, 6.0),
    ]) {
      final d = ms - at;
      if (d < 0 || d > 560) continue;
      final k = amp * math.exp(-d / 110);
      dx += k * math.sin(d * 0.11);
      dy += k * math.cos(d * 0.13);
    }
    return Offset(dx, dy);
  }

  // --- the page around the logo -------------------------------------------

  void groundLine(Size size) {
    final fade = 1 - seg(ms, 1250, 1800);
    final grow = seg(ms, 0, 520, Curves.easeOutCubic);
    if (fade <= 0 || grow <= 0) return;
    final y = layout.origin.dy + L3bLogo.ballBottom * layout.scale + 1;
    final half = size.width / 2 * grow;
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = SplashPainter._line.withValues(alpha: fade);
    canvas.drawLine(
      Offset(size.width / 2 - half, y),
      Offset(size.width / 2 + half, y),
      _paint,
    );
    _paint.style = PaintingStyle.fill;
  }

  /// A flash of color behind the logo when the 5 lands.
  void pulses(Size size) {
    _pulse(
      size,
      layout.toScreen(logo.five.center),
      SplashPainter.green,
      0.07 * bump(ms, SplashTimeline.fiveImpact, 30, 300),
    );
  }

  void _pulse(Size size, Offset center, Color color, double alpha) {
    if (alpha <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: size.width * 0.5);
    _paint
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(Offset.zero & size, _paint);
    _paint.shader = null;
  }

  // ------------------------------------------------------------------------

  void _fill(LogoPiece piece, double alpha) {
    if (alpha <= 0) return;
    _paint
      ..style = PaintingStyle.fill
      ..color = piece.color.withValues(alpha: alpha);
    canvas.drawPath(piece.path, _paint);
  }
}
