import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'goal.dart';
import 'l3b_logo.dart';
import 'logo_data.dart';
import 'player.dart';
import 'scene.dart';
import 'splash_dust.dart';
import 'splash_timeline.dart';

/// Where the scene sits on a screen: the units of the scene (see [Scene])
/// become pixels, and (0, 0) is the middle.
class SplashLayout {
  const SplashLayout(this.scale, this.center, this.halfHeight);

  factory SplashLayout.of(Size size) {
    final scale = math.min(math.min(size.width / 390, size.height / 600), 1.5);
    return SplashLayout(
      scale,
      Offset(size.width / 2, size.height / 2),
      size.height / 2 / scale,
    );
  }

  /// Pixels in one unit of the scene.
  final double scale;
  final Offset center;

  /// How far, in units, the screen goes up and down from the middle.
  final double halfHeight;

  /// How far, in units, the screen goes left and right from the middle.
  double get halfWidth => center.dx / scale;
}

/// Paints the splash at [ms] milliseconds after its start. It only depends on
/// the time, so any moment can be painted on its own.
class SplashPainter extends CustomPainter {
  const SplashPainter({required this.ms});

  final double ms;

  static const Color navy = Color(0xFF0A2B60);
  static const Color blue = Color(0xFF054FBA);
  static const Color green = Color(0xFF8DC641);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final layout = SplashLayout.of(size);
    canvas.save();
    canvas.translate(layout.center.dx, layout.center.dy);
    canvas.scale(layout.scale);
    _Frame(canvas, layout, ms).paint();
    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashPainter oldDelegate) => oldDelegate.ms != ms;
}

/// Where the ball is, and how it looks.
class _Ball {
  const _Ball({
    required this.center,
    required this.radius,
    this.spin = 0,
    this.sx = 1,
    this.sy = 1,
    this.fill = 1,
  });

  final Offset center;
  final double radius;
  final double spin;

  /// Squashed or stretched, along the axes of the screen.
  final double sx;
  final double sy;

  /// How much the piece of the ball that the 5 covers shows: it shows while
  /// the ball is on its own.
  final double fill;
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
    double speed = 1,
    double size = 1,
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
          speed: (150 + random.nextDouble() * 170) * speed,
          spin: (random.nextDouble() - 0.5) * 16,
          size: (2.6 + random.nextDouble() * 2.6) * size,
          life: 600 + random.nextDouble() * 260,
          color: colors[i % colors.length],
          turn: random.nextDouble() * math.pi,
        ),
    ];
  }

  final double angle;

  /// Units per second.
  final double speed;
  final double spin;
  final double size;

  /// Milliseconds before it is gone.
  final double life;
  final Color color;
  final double turn;
}

/// One frame: every layer of the splash at [ms], painted on [canvas] in the
/// units of the scene.
class _Frame {
  _Frame(this.canvas, this.layout, this.ms) : logo = L3bLogo.instance;

  final Canvas canvas;
  final SplashLayout layout;
  final double ms;
  final L3bLogo logo;

  final Paint _paint = Paint();

  static const double _gravity = 2400; // units per second, squared

  static final List<_Shard> _kickShards = _Shard.burst(
    seed: 21,
    count: 9,
    from: -math.pi * 0.55,
    to: math.pi * 0.05,
    speed: 0.9,
  );
  static final List<_Shard> _goalShards = _Shard.burst(
    seed: 8,
    count: 16,
    from: -math.pi,
    to: math.pi,
    speed: 1.2,
  );
  static final List<_Shard> _homeShards = _Shard.burst(
    seed: 5,
    count: 12,
    from: -math.pi * 0.95,
    to: -math.pi * 0.05,
    speed: 1.0,
    size: 1.2,
  );

  /// The player at the moment of the kick, and where his foot meets the ball.
  static final PlayerRig _strikeRig = PlayerRig(
    PlayerPoses.strike.copyWith(x: Scene.playerX + PlayerPoses.strike.x),
    ground: Scene.ground,
  );
  static final Offset _contact =
      _strikeRig.kickToe +
      const Offset(Scene.ballRadius * 0.45, -Scene.ballRadius * 0.4);

  /// How high the ball goes: near the top of the screen.
  Offset get _apex =>
      Offset(_contact.dx - 16, -math.min(262.0, layout.halfHeight - 90));

  void paint() {
    final shake = _shake();
    canvas.translate(shake.dx, shake.dy);

    _groundLine();
    _shadows();
    _dust();
    _player();

    // The logo is what is left of the text and the ball: the shine goes over
    // both of them together.
    final shining =
        ms > SplashTimeline.shineStart && ms < SplashTimeline.shineEnd;
    final pop = _logoIn;
    canvas.save();
    canvas.scale(0.94 + 0.06 * pop);
    // While it comes in, the logo fades as one piece: its parts overlap.
    if (shining || pop < 1) {
      canvas.saveLayer(
        Rect.fromCenter(
          center: Offset.zero,
          width: Scene.logoWidth + 80,
          height: Scene.logoWidth * 0.8,
        ),
        Paint()..color = Color.fromRGBO(0, 0, 0, pop),
      );
    }
    // The text is behind the ball, until the ball comes home to where the 5
    // is pressed into it.
    final textOnTop = ms >= SplashTimeline.unformEnd - 100;
    if (!textOnTop) _letters();
    _ball();
    if (textOnTop) _letters();
    if (shining) _shine();
    if (shining || pop < 1) canvas.restore();
    canvas.restore();

    _goal();
    _effects();
  }

  // --- the ball -----------------------------------------------------------

  _Ball _ballAt(double time) {
    final rest = Scene.logoBall;
    const rLogo = Scene.logoBallRadius;
    const rGame = Scene.ballRadius;
    final apex = _apex;

    if (time < SplashTimeline.launch) {
      // It crouches before it is thrown.
      final c = seg(
        time,
        SplashTimeline.squash,
        SplashTimeline.launch,
        Curves.easeIn,
      );
      final sy = 1 - 0.16 * c;
      return _Ball(
        center: rest + Offset(0, rLogo * (1 - sy)),
        radius: rLogo,
        sx: 1 + 0.12 * c,
        sy: sy,
        fill: 0,
      );
    }
    if (time < SplashTimeline.apex) {
      final u =
          (time - SplashTimeline.launch) /
          (SplashTimeline.apex - SplashTimeline.launch);
      final up = 1 - (1 - u) * (1 - u);
      final across = Curves.easeInOut.transform(u);
      final stretch = 1 + 0.2 * math.pow(1 - u, 2);
      return _Ball(
        center: Offset(
          lerpDouble(rest.dx, apex.dx, across)!,
          lerpDouble(rest.dy, apex.dy, up)!,
        ),
        radius: lerpDouble(rLogo, rGame, Curves.easeOutCubic.transform(u))!,
        spin: math.pi * 6 * Curves.easeOut.transform(u),
        sx: 1 / math.sqrt(stretch),
        sy: stretch,
        fill: seg(
          time,
          SplashTimeline.launch,
          SplashTimeline.launch + 70,
          Curves.easeOut,
        ),
      );
    }
    const turns = math.pi * 6;
    if (time < SplashTimeline.strike) {
      // It falls on the foot of the player.
      final u =
          (time - SplashTimeline.apex) /
          (SplashTimeline.strike - SplashTimeline.apex);
      return _Ball(
        center: Offset(
          lerpDouble(apex.dx, _contact.dx, Curves.easeInOut.transform(u))!,
          lerpDouble(apex.dy, _contact.dy, u * u)!,
        ),
        radius: rGame,
        spin: turns + 3.2 * (time - SplashTimeline.apex) / 1000,
      );
    }
    final spinAtKick =
        turns + 3.2 * (SplashTimeline.strike - SplashTimeline.apex) / 1000;
    if (time < SplashTimeline.goal) {
      // The shot.
      final u =
          (time - SplashTimeline.strike) /
          (SplashTimeline.goal - SplashTimeline.strike);
      final e = 1 - math.pow(1 - u, 1.5).toDouble();
      final control = Offset(70, Scene.netHit.dy - 34);
      return _Ball(
        center: _bezier(_contact, control, Scene.netHit, e),
        radius: rGame,
        spin: spinAtKick + 24 * (time - SplashTimeline.strike) / 1000,
      );
    }
    final spinInNet =
        spinAtKick + 24 * (SplashTimeline.goal - SplashTimeline.strike) / 1000;
    if (time < SplashTimeline.comeBack) {
      return _ballInNet(time, spinInNet);
    }
    if (time < SplashTimeline.land) {
      // Back home, growing as it comes near.
      final from = _ballInNet(SplashTimeline.comeBack, spinInNet);
      final u =
          (time - SplashTimeline.comeBack) /
          (SplashTimeline.land - SplashTimeline.comeBack);
      final e = Curves.easeInOut.transform(u);
      final control = Offset(20, rest.dy - 190);
      final spinTo =
          (from.spin / (math.pi * 2)).floor() * math.pi * 2 - math.pi * 4;
      return _Ball(
        center: _bezier(from.center, control, rest, e),
        radius: lerpDouble(rGame, rLogo, Curves.easeIn.transform(u))!,
        spin: lerpDouble(from.spin, spinTo, e)!,
      );
    }
    // At home: it squashes a little as it settles.
    final d = time - SplashTimeline.land;
    final squash = 0.17 * math.exp(-math.pow(d / 70, 2));
    final sy = 1 - squash;
    return _Ball(
      center: rest + Offset(0, rLogo * (1 - sy)),
      radius: rLogo,
      sx: 1 + 0.8 * squash,
      sy: sy,
      fill: 1 - seg(time, SplashTimeline.land + 10, SplashTimeline.land + 40),
    );
  }

  /// The ball in the net: pushed back, then it falls and bounces on the
  /// ground inside the goal.
  _Ball _ballInNet(double time, double spinAtGoal) {
    final tau = (time - SplashTimeline.goal) / 1000;
    const floor = Scene.ground - Scene.ballRadius - 1;
    final x = Scene.netHit.dx - 9 * (1 - math.exp(-tau * 14));
    final y = _fallOnto(floor, Scene.netHit.dy, -40, tau);
    return _Ball(
      center: Offset(x, y),
      radius: Scene.ballRadius,
      spin: spinAtGoal - 8 * (1 - math.exp(-tau * 5)),
    );
  }

  /// Height of something thrown at [vy] (negative is up) from [y0] after [t]
  /// seconds, that loses most of its speed each time it hits [floor].
  double _fallOnto(double floor, double y0, double vy, double t) {
    var y = y0;
    var v = vy;
    for (var i = 0; i < 5; i++) {
      final reach =
          (-v + math.sqrt(v * v + 2 * _gravity * (floor - y))) / _gravity;
      if (t <= reach) return y + v * t + 0.5 * _gravity * t * t;
      v = -(v + _gravity * reach) * 0.34;
      y = floor;
      t -= reach;
    }
    return floor;
  }

  static Offset _bezier(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  void _ball() {
    final ball = _ballAt(ms);
    final fast = (ball.center - _ballAt(ms - 34).center).distance;
    final trail = ((fast - 5) / 28).clamp(0.0, 1.0);
    if (trail > 0 && ms > SplashTimeline.launch) {
      const alphas = [0.20, 0.12, 0.06];
      for (var i = alphas.length; i >= 1; i--) {
        final time = ms - 34.0 * i;
        if (time < SplashTimeline.launch) continue;
        _drawBall(_ballAt(time), alphas[i - 1] * trail);
      }
    }
    _drawStreak();
    _drawBall(ball, 1, solid: true);
  }

  /// The shot leaves a green line behind it, like the stroke of the 5.
  void _drawStreak() {
    if (ms < SplashTimeline.strike || ms > SplashTimeline.goal + 80) return;
    const pieces = 8;
    final fade = 1 - seg(ms, SplashTimeline.goal, SplashTimeline.goal + 80);
    for (var i = 0; i < pieces; i++) {
      final a = _ballAt(math.max(ms - i * 9, SplashTimeline.strike)).center;
      final b = _ballAt(
        math.max(ms - (i + 1) * 9, SplashTimeline.strike),
      ).center;
      final k = 1 - i / pieces;
      _paint
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1 + 7 * k
        ..color = SplashPainter.green.withValues(alpha: 0.6 * k * fade);
      canvas.drawLine(a, b, _paint);
    }
    _paint.style = PaintingStyle.fill;
  }

  void _drawBall(_Ball ball, double alpha, {bool solid = false}) {
    canvas.save();
    canvas.translate(ball.center.dx, ball.center.dy);
    canvas.scale(ball.sx, ball.sy);
    canvas.rotate(ball.spin);
    canvas.scale(ball.radius / kBallRadius);
    canvas.translate(-kBallCx, -kBallCy);
    if (solid && ball.fill > 0) {
      // A ball on its own is whole: what is behind does not show between its
      // patches.
      _paint
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFFFFFF).withValues(alpha: ball.fill);
      canvas.drawCircle(L3bLogo.ballCenter, kBallRadius - 1, _paint);
    }
    _fill(logo.ballFill, alpha * ball.fill);
    for (final piece in logo.ball) {
      _fill(piece, alpha);
    }
    canvas.restore();
  }

  // --- the letters, the player and the dust between -----------------------

  /// How much the logo (the text and the ball) shows as it comes in.
  double get _logoIn => seg(ms, 0, SplashTimeline.logoIn, Curves.easeOut);

  void _letters() {
    double alpha;
    if (ms < SplashTimeline.formStart) {
      alpha = 1;
    } else if (ms < SplashTimeline.unformEnd - 70) {
      alpha =
          1 - seg(ms, SplashTimeline.formStart, SplashTimeline.formStart + 70);
    } else {
      alpha = seg(
        ms,
        SplashTimeline.unformEnd - 70,
        SplashTimeline.unformEnd + 30,
      );
    }
    if (alpha <= 0) return;
    canvas.save();
    canvas.scale(Scene.logoScale);
    canvas.translate(-kLogoWidth / 2, -kLogoHeight / 2);
    _fill(logo.five, alpha);
    _fill(logo.swoosh, alpha);
    for (final letter in logo.letters) {
      _fill(letter, alpha);
    }
    canvas.restore();
  }

  void _dust() {
    final dust = SplashDust.instance;
    if (ms >= SplashTimeline.formStart && ms < SplashTimeline.formEnd + 60) {
      dust.forward.paint(
        canvas,
        seg(ms, SplashTimeline.formStart, SplashTimeline.formEnd),
        alpha: 1 - seg(ms, SplashTimeline.formEnd, SplashTimeline.formEnd + 50),
      );
    }
    if (ms >= SplashTimeline.unformStart &&
        ms < SplashTimeline.unformEnd + 70) {
      dust.reverse.paint(
        canvas,
        seg(ms, SplashTimeline.unformStart, SplashTimeline.unformEnd),
        alpha:
            1 -
            seg(
              ms,
              SplashTimeline.unformEnd + 10,
              SplashTimeline.unformEnd + 60,
            ),
      );
    }
  }

  /// How the player stands at [time].
  PlayerPose _poseAt(double time) {
    PlayerPose pose;
    if (time < SplashTimeline.backswing) {
      pose = PlayerPose.lerp(
        PlayerPoses.ready,
        PlayerPoses.backswing,
        seg(
          time,
          SplashTimeline.formEnd,
          SplashTimeline.backswing,
          Curves.easeInOut,
        ),
      );
    } else if (time < SplashTimeline.strike) {
      pose = PlayerPose.lerp(
        PlayerPoses.backswing,
        PlayerPoses.strike,
        seg(
          time,
          SplashTimeline.backswing,
          SplashTimeline.strike,
          Curves.easeInCubic,
        ),
      );
    } else if (time < SplashTimeline.followThrough) {
      pose = PlayerPose.lerp(
        PlayerPoses.strike,
        PlayerPoses.follow,
        seg(
          time,
          SplashTimeline.strike,
          SplashTimeline.followThrough,
          Curves.easeOutCubic,
        ),
      );
    } else {
      pose = PlayerPose.lerp(
        PlayerPoses.follow,
        PlayerPoses.cheer,
        seg(
          time,
          SplashTimeline.followThrough,
          SplashTimeline.jumpApex,
          Curves.easeInOut,
        ),
      );
    }
    // The jump: up when the ball is in, down again after the cheer.
    var lift = pose.lift;
    if (time >= SplashTimeline.followThrough) {
      lift = time < SplashTimeline.jumpApex
          ? lerpDouble(
              8,
              30,
              Curves.easeOut.transform(
                seg(
                  time,
                  SplashTimeline.followThrough,
                  SplashTimeline.jumpApex,
                ),
              ),
            )!
          : lerpDouble(
              30,
              0,
              Curves.easeIn.transform(
                seg(time, SplashTimeline.jumpApex, SplashTimeline.jumpEnd),
              ),
            )!;
    }
    return pose.copyWith(lift: lift, x: Scene.playerX + pose.x);
  }

  double get _playerAlpha {
    return ms < SplashTimeline.unformStart
        ? seg(ms, SplashTimeline.formEnd - 70, SplashTimeline.formEnd + 30)
        : 1 -
              seg(
                ms,
                SplashTimeline.unformStart,
                SplashTimeline.unformStart + 60,
              );
  }

  void _player() {
    final alpha = _playerAlpha;
    if (alpha <= 0) return;
    // A faint trail behind the leg as it kicks.
    if (ms > SplashTimeline.strike - 90 && ms < SplashTimeline.strike + 70) {
      const alphas = [0.20, 0.12, 0.06];
      for (var i = alphas.length; i >= 1; i--) {
        PlayerRig(
          _poseAt(ms - 16.0 * i),
          ground: Scene.ground,
        ).paintKickingLeg(canvas, alphas[i - 1] * alpha);
      }
    }
    PlayerRig(
      _poseAt(ms),
      ground: Scene.ground,
    ).paint(canvas, alpha: alpha, number: logo.five.path);
  }

  // --- the pitch ----------------------------------------------------------

  void _groundLine() {
    final grow = seg(
      ms,
      SplashTimeline.formStart + 100,
      SplashTimeline.formStart + 520,
      Curves.easeOutCubic,
    );
    final fade =
        1 -
        seg(ms, SplashTimeline.comeBack + 100, SplashTimeline.comeBack + 520);
    if (grow <= 0 || fade <= 0) return;
    final reach = layout.halfWidth * grow;
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD3DDEC).withValues(alpha: fade);
    canvas.drawLine(
      Offset(-reach, Scene.ground + 1),
      Offset(reach, Scene.ground + 1),
      _paint,
    );
    _paint.style = PaintingStyle.fill;
  }

  void _shadows() {
    final fade =
        1 -
        seg(ms, SplashTimeline.comeBack + 100, SplashTimeline.comeBack + 520);
    if (fade <= 0) return;
    _paint
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // The player's.
    final playerAlpha = _playerAlpha;
    if (playerAlpha > 0) {
      final pose = _poseAt(ms);
      final high = (pose.lift / 30).clamp(0.0, 1.0);
      _paint.color = SplashPainter.navy.withValues(
        alpha: 0.13 * playerAlpha * fade * (1 - 0.5 * high),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pose.x + 4, Scene.ground + 2),
          width: 56 * (1 - 0.25 * high),
          height: 6,
        ),
        _paint,
      );
    }

    // The ball's: small and faint when the ball is high.
    if (ms > SplashTimeline.launch + 100 &&
        ms < SplashTimeline.comeBack + 520) {
      final ball = _ballAt(ms);
      final high = (Scene.ground - ball.center.dy).clamp(0.0, 400.0) / 400;
      final alpha =
          0.16 *
          (1 - high) *
          fade *
          seg(ms, SplashTimeline.launch + 100, SplashTimeline.launch + 400);
      if (alpha > 0.005) {
        _paint.color = SplashPainter.navy.withValues(alpha: alpha);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(ball.center.dx, Scene.ground + 2),
            width: ball.radius * 2 * (1 - 0.5 * high),
            height: ball.radius * 0.5,
          ),
          _paint,
        );
      }
    }
    _paint.maskFilter = null;
  }

  void _goal() {
    final alpha =
        seg(
          ms,
          SplashTimeline.formStart + 150,
          SplashTimeline.formStart + 600,
          Curves.easeOut,
        ) *
        (1 -
            seg(
              ms,
              SplashTimeline.comeBack + 20,
              SplashTimeline.comeBack + 450,
            ));
    if (alpha <= 0) return;
    final slide =
        24 *
        (1 -
            seg(
              ms,
              SplashTimeline.formStart + 150,
              SplashTimeline.formStart + 650,
              Curves.easeOutCubic,
            ));
    canvas.save();
    canvas.translate(slide, 0);
    GoalPainter().paint(canvas, ms: ms - SplashTimeline.goal, alpha: alpha);
    canvas.restore();
  }

  // --- the shine ----------------------------------------------------------

  /// A band of light over the logo, only where there is something to light.
  void _shine() {
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
    canvas.save();
    canvas.scale(Scene.logoScale);
    canvas.translate(-kLogoWidth / 2, -kLogoHeight / 2);
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
    canvas.restore();
  }

  // --- what happens when things land --------------------------------------

  void _effects() {
    // The kick: a ring and lines where the foot meets the ball, and shards.
    final kick = ms - SplashTimeline.strike;
    if (kick > 0 && kick < 600) {
      final e = Curves.easeOutCubic.transform(
        seg(ms, SplashTimeline.strike, SplashTimeline.strike + 420),
      );
      _ring(
        Rect.fromCircle(center: _contact, radius: 8 + 52 * e),
        SplashPainter.green.withValues(alpha: 0.55 * (1 - e)),
        4 * (1 - e) + 0.8,
      );
      final lines = Curves.easeOut.transform(
        seg(ms, SplashTimeline.strike, SplashTimeline.strike + 230),
      );
      if (lines < 1) {
        _paint
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.4 * (1 - lines) + 0.6
          ..color = SplashPainter.green.withValues(alpha: 0.9 * (1 - lines));
        for (var i = 0; i < 8; i++) {
          final a = -math.pi * 0.62 + i * math.pi * 0.2;
          final dir = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(
            _contact + dir * (14 + 12 * lines),
            _contact + dir * (26 + 30 * lines),
            _paint,
          );
        }
        _paint.style = PaintingStyle.fill;
      }
      _shards(_kickShards, SplashTimeline.strike, _contact);
    }

    // The goal: rings in the net, and a burst.
    final inNet = ms - SplashTimeline.goal;
    if (inNet > 0 && inNet < 900) {
      for (final (delay, color, alpha, reach) in [
        (0.0, SplashPainter.green, 0.5, 120.0),
        (90.0, SplashPainter.blue, 0.38, 90.0),
      ]) {
        final e = Curves.easeOutCubic.transform(
          seg(
            ms,
            SplashTimeline.goal + delay,
            SplashTimeline.goal + delay + 650,
          ),
        );
        if (e <= 0 || e >= 1) continue;
        _ring(
          Rect.fromCircle(center: Scene.netHit, radius: 10 + reach * e),
          color.withValues(alpha: alpha * math.pow(1 - e, 1.3).toDouble()),
          4.5 * (1 - e) + 0.8,
        );
      }
      _shards(_goalShards, SplashTimeline.goal, Scene.netHit);
    }

    // Home: a ring on the ground of the logo, and a burst to both sides.
    final home = ms - SplashTimeline.land;
    if (home > 0 && home < 900) {
      final bottom = Scene.logoBall + const Offset(0, Scene.logoBallRadius + 2);
      for (final (delay, color, alpha) in [
        (0.0, SplashPainter.blue, 0.34),
        (90.0, SplashPainter.green, 0.38),
      ]) {
        final e = Curves.easeOutCubic.transform(
          seg(
            ms,
            SplashTimeline.land + delay,
            SplashTimeline.land + delay + 700,
          ),
        );
        if (e <= 0 || e >= 1) continue;
        final rx = Scene.logoBallRadius * (0.9 + 2.0 * e);
        _ring(
          Rect.fromCenter(center: bottom, width: rx * 2, height: rx * 0.34),
          color.withValues(alpha: alpha * math.pow(1 - e, 1.3).toDouble()),
          3 * (1 - e) + 0.7,
        );
      }
      _shards(_homeShards, SplashTimeline.land, bottom);
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

  void _shards(List<_Shard> shards, double at, Offset origin) {
    final age = ms - at;
    if (age <= 0) return;
    for (final shard in shards) {
      if (age >= shard.life) continue;
      final s = age / 1000;
      final life = age / shard.life;
      final x = origin.dx + math.cos(shard.angle) * shard.speed * s;
      final y =
          origin.dy +
          math.sin(shard.angle) * shard.speed * s +
          0.5 * 520 * s * s;
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
        _paint
          ..style = PaintingStyle.fill
          ..color = shard.color.withValues(alpha: alpha),
      );
    }
  }

  /// The whole scene shakes a little when something lands (units).
  Offset _shake() {
    var dx = 0.0;
    var dy = 0.0;
    for (final (at, amp) in [
      (SplashTimeline.strike, 2.5),
      (SplashTimeline.goal, 4.0),
      (SplashTimeline.land, 3.5),
    ]) {
      final d = ms - at;
      if (d < 0 || d > 520) continue;
      final k = amp * math.exp(-d / 110);
      dx += k * math.sin(d * 0.11);
      dy += k * math.cos(d * 0.13);
    }
    return Offset(dx, dy);
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
