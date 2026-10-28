import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'ball_track.dart';
import 'l3b_logo.dart';
import 'logo_data.dart';
import 'player.dart';
import 'scene.dart';
import 'siu_text.dart';
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

/// A piece of paper thrown up when he shouts "Siuuu".
class _Confetti {
  const _Confetti({
    required this.angle,
    required this.speed,
    required this.width,
    required this.height,
    required this.turn,
    required this.spin,
    required this.flip,
    required this.delay,
    required this.life,
    required this.color,
  });

  static List<_Confetti> burst({required int seed, required int count}) {
    final random = math.Random(seed);
    const colors = [
      SplashPainter.navy,
      SplashPainter.blue,
      SplashPainter.green,
      SplashPainter.green,
      Color(0xFFB9DD83),
    ];
    return [
      for (var i = 0; i < count; i++)
        _Confetti(
          angle: -math.pi * (0.1 + 0.8 * random.nextDouble()),
          speed: 210 + random.nextDouble() * 190,
          width: 2.6 + random.nextDouble() * 2,
          height: 5.2 + random.nextDouble() * 3.4,
          turn: random.nextDouble() * math.pi,
          spin: (random.nextDouble() - 0.5) * 14,
          flip: 6 + random.nextDouble() * 8,
          delay: random.nextDouble() * 110,
          life: 1000 + random.nextDouble() * 500,
          color: colors[i % colors.length],
        ),
    ];
  }

  final double angle;

  /// Units per second.
  final double speed;
  final double width;
  final double height;
  final double turn;
  final double spin;

  /// How fast it turns over (it is thin when seen edge on).
  final double flip;

  /// Milliseconds after the landing, and how long it lasts.
  final double delay;
  final double life;
  final Color color;
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

  static final List<_Shard> _kickShards = _Shard.burst(
    seed: 21,
    count: 9,
    from: -math.pi * 0.55,
    to: math.pi * 0.05,
    speed: 0.9,
  );
  static final List<_Shard> _siuShards = _Shard.burst(
    seed: 13,
    count: 12,
    from: -math.pi * 0.95,
    to: -math.pi * 0.05,
    speed: 0.9,
    size: 1.1,
  );
  static final List<_Shard> _homeShards = _Shard.burst(
    seed: 5,
    count: 12,
    from: -math.pi * 0.95,
    to: -math.pi * 0.05,
    speed: 1.0,
    size: 1.2,
  );

  static final List<_Confetti> _confetti = _Confetti.burst(seed: 31, count: 64);

  /// A second, smaller burst, while he is still shouting.
  static final List<_Confetti> _confetti2 = _Confetti.burst(
    seed: 47,
    count: 40,
  );
  static const double _secondBurst = 560;

  /// The player has his back to where the ball goes: he faces left.
  static const double _facing = -1;

  /// Where the ball is at every moment.
  late final BallTrack track = BallTrack(
    halfWidth: layout.halfWidth,
    halfHeight: layout.halfHeight,
  );

  void paint() {
    final shake = _shake();
    canvas.translate(shake.dx, shake.dy);
    final zoom = _zoom();
    if (zoom != 1) canvas.scale(zoom);

    _shadows();
    _glow();
    // The paper comes up from behind him.
    _confettiBurst();
    _dust();
    _player();

    // The logo is what is left of the text and the ball: the shine goes over
    // both of them together.
    final shining =
        ms > SplashTimeline.shineStart && ms < SplashTimeline.shineEnd;
    final pop = _logoIn;
    canvas.save();
    // The logo comes in a little small and grows, and it takes the landing of
    // the ball with a small bounce.
    final landing = math.sin(
      math.pi * seg(ms, SplashTimeline.land, SplashTimeline.land + 220),
    );
    canvas.scale(0.94 + 0.06 * pop + 0.022 * landing);
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
    // The text is behind the ball, until the ball comes home: then the 5 is
    // pressed into it.
    final textOnTop = ms >= SplashTimeline.land;
    if (!textOnTop) _letters();
    _ball();
    if (textOnTop) _letters();
    if (shining) _shine();
    if (shining || pop < 1) canvas.restore();
    _sparkles();
    canvas.restore();

    _effects();
  }

  // --- the ball -----------------------------------------------------------

  void _ball() {
    final ball = track.at(ms);
    final fast = (ball.center - track.at(ms - 34).center).distance;
    final trail = ((fast - 5) / 28).clamp(0.0, 1.0);
    if (trail > 0 && ms > SplashTimeline.launch) {
      const alphas = [0.20, 0.12, 0.06];
      for (var i = alphas.length; i >= 1; i--) {
        final time = ms - 34.0 * i;
        if (time < SplashTimeline.launch) continue;
        _drawBall(track.at(time), alphas[i - 1] * trail);
      }
    }
    _drawStreak();
    _drawBall(ball, 1, solid: true);
  }

  /// The shot leaves a green line behind it, like the stroke of the 5.
  void _drawStreak() {
    if (ms < SplashTimeline.strike || ms > track.exit) return;
    const pieces = 8;
    final fade = 1 - seg(ms, track.exit - 40, track.exit);
    for (var i = 0; i < pieces; i++) {
      final a = track.at(math.max(ms - i * 9, SplashTimeline.strike)).center;
      final b = track
          .at(math.max(ms - (i + 1) * 9, SplashTimeline.strike))
          .center;
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

  void _drawBall(BallState ball, double alpha, {bool solid = false}) {
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
      alpha = seg(ms, SplashTimeline.unformEnd - 90, SplashTimeline.land);
    }
    if (alpha <= 0) return;
    canvas.save();
    canvas.scale(Scene.logoScale);
    canvas.translate(-kLogoWidth / 2, -kLogoHeight / 2);

    // As the logo comes in, the pieces come one after the other: the 5, then
    // the letters, each rising into its place a little past it, and the stroke
    // of the 5 is drawn from its start to its tip.
    final intro = ms < SplashTimeline.formStart;
    double rise(double delay) =>
        intro ? (1 - seg(ms, delay, delay + 230, Curves.easeOutBack)) * 30 : 0;
    void piece(LogoPiece p, double delay) {
      canvas.save();
      canvas.translate(0, rise(delay));
      _fill(p, alpha);
      canvas.restore();
    }

    piece(logo.five, 0);
    if (intro) {
      final wipe = seg(ms, 30, 300, Curves.easeOutCubic);
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(-50, 0, (kLogoWidth + 100) * wipe, 500));
      _fill(logo.swoosh, alpha);
      canvas.restore();
    } else {
      _fill(logo.swoosh, alpha);
    }
    for (var i = 0; i < logo.letters.length; i++) {
      piece(logo.letters[i], 45.0 * (i + 1));
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
    PlayerPose between(
      PlayerPose a,
      PlayerPose b,
      double from,
      double to,
      Curve curve,
    ) => PlayerPose.lerp(a, b, seg(time, from, to, curve));
    final PlayerPose pose;
    if (time < SplashTimeline.crouch) {
      pose = between(
        PlayerPoses.ready,
        PlayerPoses.crouch,
        SplashTimeline.formEnd,
        SplashTimeline.crouch,
        Curves.easeInOut,
      );
    } else if (time < SplashTimeline.takeOff) {
      pose = between(
        PlayerPoses.crouch,
        PlayerPoses.takeOff,
        SplashTimeline.crouch,
        SplashTimeline.takeOff,
        Curves.easeOut,
      );
    } else if (time < SplashTimeline.scissors) {
      pose = between(
        PlayerPoses.takeOff,
        PlayerPoses.scissors,
        SplashTimeline.takeOff,
        SplashTimeline.scissors,
        Curves.easeInOut,
      );
    } else if (time < SplashTimeline.strike) {
      pose = between(
        PlayerPoses.scissors,
        PlayerPoses.strike,
        SplashTimeline.scissors,
        SplashTimeline.strike,
        Curves.easeInOutCubic,
      );
    } else if (time < SplashTimeline.fall) {
      pose = between(
        PlayerPoses.strike,
        PlayerPoses.fall,
        SplashTimeline.strike,
        SplashTimeline.fall,
        Curves.easeOut,
      );
    } else if (time < SplashTimeline.lying) {
      pose = between(
        PlayerPoses.fall,
        PlayerPoses.lying,
        SplashTimeline.fall,
        SplashTimeline.lying,
        Curves.easeIn,
      );
    } else if (time < SplashTimeline.getUp) {
      pose = PlayerPoses.lying;
    } else if (time < SplashTimeline.siuCrouch) {
      // Up from the ground into a crouch.
      pose = between(
        PlayerPoses.lying,
        PlayerPoses.crouch,
        SplashTimeline.getUp,
        SplashTimeline.siuCrouch,
        Curves.easeInOutCubic,
      );
    } else if (time < SplashTimeline.siuJump) {
      pose = PlayerPoses.crouch;
    } else if (time < SplashTimeline.siuPeak) {
      // The jump: he starts to turn to face us.
      pose = between(
        PlayerPoses.crouch,
        PlayerPoses.siuAir,
        SplashTimeline.siuJump,
        SplashTimeline.siuPeak,
        Curves.easeOut,
      );
    } else if (time < SplashTimeline.siuLand) {
      // The turn is done as he comes down, with the legs and arms going wide.
      pose = between(
        PlayerPoses.siuAir,
        PlayerPoses.siuLand,
        SplashTimeline.siuPeak,
        SplashTimeline.siuLand,
        Curves.easeIn,
      );
    } else if (time < SplashTimeline.siuSettle) {
      // The landing takes the knees down, and he stands up straight.
      pose = between(
        PlayerPoses.siuLand,
        PlayerPoses.siu,
        SplashTimeline.siuLand,
        SplashTimeline.siuSettle,
        Curves.easeOutCubic,
      );
    } else {
      // He pumps his chest while he shouts, and stands as he was when it is
      // time to turn into the letters.
      final calm =
          1 -
          seg(
            time,
            SplashTimeline.unformStart - 220,
            SplashTimeline.unformStart,
          );
      final wave =
          (0.5 +
              0.5 *
                  math.sin(
                    (time - SplashTimeline.siuSettle) * 0.011 - math.pi / 2,
                  )) *
          calm;
      pose = PlayerPose.lerp(PlayerPoses.siu, PlayerPoses.siuPump, wave);
    }
    // The jump is an arc: up quickly, a moment at the top, down.
    var lift = pose.lift;
    if (time >= SplashTimeline.siuJump && time < SplashTimeline.siuLand) {
      final u =
          (time - SplashTimeline.siuJump) /
          (SplashTimeline.siuLand - SplashTimeline.siuJump);
      lift = 58 * 4 * u * (1 - u);
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
    // A faint trail behind the leg as it swings over his head.
    if (ms > SplashTimeline.scissors && ms < SplashTimeline.strike + 90) {
      const alphas = [0.17, 0.10, 0.05];
      for (var i = alphas.length; i >= 1; i--) {
        PlayerRig(
          _poseAt(ms - 9.0 * i),
          ground: Scene.ground,
          facing: _facing,
        ).paintKickingLeg(canvas, alphas[i - 1] * alpha);
      }
    }
    PlayerRig(
      _poseAt(ms),
      ground: Scene.ground,
      facing: _facing,
    ).paint(canvas, alpha: alpha, number: logo.five.path);
  }

  // --- the pitch ----------------------------------------------------------

  void _shadows() {
    final fade =
        1 -
        seg(ms, SplashTimeline.comeBack + 100, SplashTimeline.comeBack + 520);
    if (fade <= 0) return;
    _paint
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // The player's: under his body, small and faint when he is in the air.
    final playerAlpha = _playerAlpha;
    if (playerAlpha > 0) {
      final pose = _poseAt(ms);
      final rig = PlayerRig(pose, ground: Scene.ground, facing: _facing);
      final high = ((Scene.ground - rig.hip.dy - 82) / 90).clamp(0.0, 1.0);
      final flat = (pose.roll / 1.4).clamp(0.0, 1.0);
      _paint.color = SplashPainter.navy.withValues(
        alpha: 0.13 * playerAlpha * fade * (1 - 0.6 * high),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            lerpDouble(rig.hip.dx, (rig.hip.dx + rig.head.dx) / 2, flat)!,
            Scene.ground + 2,
          ),
          width: (56 + 60 * flat) * (1 - 0.3 * high),
          height: 6,
        ),
        _paint,
      );
    }

    // The ball's: small and faint when the ball is high.
    if (ms > SplashTimeline.launch + 100 &&
        ms < SplashTimeline.comeBack + 520) {
      final ball = track.at(ms);
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

  /// Little stars of light on the logo, each one flashing as the band of light
  /// goes over it.
  void _sparkles() {
    if (ms < SplashTimeline.shineStart - 60 || ms > SplashTimeline.total) {
      return;
    }
    // Where, in the units of the logo, and how big.
    const stars = [
      (Offset(92, 74), 1.0),
      (Offset(352, 122), 0.8),
      (Offset(742, 168), 0.9),
      (Offset(878, 108), 0.7),
      (Offset(1024, 268), 1.0),
    ];
    const width = 170.0;
    const lean = 110.0;
    const from = -width - lean;
    const to = kLogoWidth + 40;
    canvas.save();
    canvas.scale(Scene.logoScale);
    canvas.translate(-kLogoWidth / 2, -kLogoHeight / 2);
    for (final (at, size) in stars) {
      // When the middle of the band is over the star: the band moves along an
      // ease, so ask the ease where it is.
      final target = ((at.dx - (lean + width) / 2 - from) / (to - from)).clamp(
        0.0,
        1.0,
      );
      var lo = 0.0;
      var hi = 1.0;
      for (var i = 0; i < 18; i++) {
        final mid = (lo + hi) / 2;
        if (Curves.easeInOutCubic.transform(mid) < target) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      final when =
          SplashTimeline.shineStart +
          lo * (SplashTimeline.shineEnd - SplashTimeline.shineStart);
      final k = seg(ms, when - 60, when + 200);
      if (k <= 0 || k >= 1) continue;
      final flash = math.pow(math.sin(math.pi * k), 1.4).toDouble();
      final radius = 64 * size * flash;
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final a = -math.pi / 2 + i * math.pi / 4 + 0.3 * (k - 0.5);
        final r = i.isEven ? radius : radius * 0.2;
        final p = at + Offset(math.cos(a) * r, math.sin(a) * r);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      _paint
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * flash);
      canvas.drawCircle(at, radius * 0.38, _paint);
      canvas.drawPath(
        path,
        _paint..color = Colors.white.withValues(alpha: flash),
      );
    }
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
        Rect.fromCircle(center: BallTrack.contact, radius: 8 + 52 * e),
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
            BallTrack.contact + dir * (14 + 12 * lines),
            BallTrack.contact + dir * (26 + 30 * lines),
            _paint,
          );
        }
        _paint.style = PaintingStyle.fill;
      }
      _shards(_kickShards, SplashTimeline.strike, BallTrack.contact);
    }

    // "Siuuu": a ring under his feet and a burst when he lands, and rays from
    // his head while he shouts.
    final siu = ms - SplashTimeline.siuLand;
    if (siu > 0 && siu < 900) {
      final rig = PlayerRig(
        _poseAt(SplashTimeline.siuLand),
        ground: Scene.ground,
        facing: _facing,
      );
      final feet = Offset(rig.hip.dx, Scene.ground + 2);
      for (final (delay, color, alpha) in [
        (0.0, SplashPainter.blue, 0.34),
        (90.0, SplashPainter.green, 0.4),
      ]) {
        final e = Curves.easeOutCubic.transform(
          seg(
            ms,
            SplashTimeline.siuLand + delay,
            SplashTimeline.siuLand + delay + 650,
          ),
        );
        if (e <= 0 || e >= 1) continue;
        final rx = 30 + 90 * e;
        _ring(
          Rect.fromCenter(center: feet, width: rx * 2, height: rx * 0.3),
          color.withValues(alpha: alpha * math.pow(1 - e, 1.3).toDouble()),
          3 * (1 - e) + 0.7,
        );
      }
      _shards(_siuShards, SplashTimeline.siuLand, feet);
    }
    _shoutRays();
    _siuWord();

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

  /// Where he stands when he has landed, and where his chest is.
  Offset get _siuChest {
    final rig = PlayerRig(
      _poseAt(SplashTimeline.siuSettle),
      ground: Scene.ground,
      facing: _facing,
    );
    return Offset(rig.hip.dx, rig.hip.dy - 26);
  }

  /// Where his head is when he has landed.
  Offset get _siuHead => PlayerRig(
    _poseAt(SplashTimeline.siuSettle),
    ground: Scene.ground,
    facing: _facing,
  ).head;

  /// The word "SIUUU" over his head, as he shouts it: the letters pop up one
  /// after the other, bounce a little as they stay, and rise and fade when he
  /// stops.
  void _siuWord() {
    final start = SplashTimeline.siuLand + 15;
    final end = SplashTimeline.unformStart + 120;
    if (ms < start || ms > end) return;
    final head = _siuHead;
    // Over the rays.
    final baseline = head.dy - PlayerRig.headRadius - 50;
    final out = seg(
      ms,
      SplashTimeline.unformStart - 120,
      SplashTimeline.unformStart + 100,
      Curves.easeIn,
    );
    var x = head.dx - SiuText.width / 2;
    for (var i = 0; i < SiuText.word.length; i++) {
      final letter = SiuText.word[i];
      final w = SiuText.widthOf(letter);
      final begin = start + 55.0 * i;
      final pop = seg(ms, begin, begin + 260, Curves.easeOutBack);
      final centre = x + w / 2;
      x += w + SiuText.gap;
      if (pop <= 0) continue;
      final alpha = seg(ms, begin, begin + 100) * (1 - out);
      final bounce =
          1.4 *
          math.sin(ms * 0.014 - i * 0.9) *
          seg(ms, begin + 260, begin + 420);
      final scale = (0.2 + 0.8 * pop) * (1 + 0.18 * out);
      final path = SiuText.letter(letter, SiuText.height * SiuText.growth[i]);
      canvas.save();
      canvas.translate(centre, baseline + bounce - 9 * out);
      canvas.scale(scale);
      canvas.skew(-SiuText.slant, 0);
      canvas.translate(-w / 2, 0);
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = SiuText.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter;
      // A navy shadow, then the letter in the green of the 5.
      canvas.save();
      canvas.translate(1.7, 2.3);
      canvas.drawPath(
        path,
        _paint..color = SplashPainter.navy.withValues(alpha: alpha),
      );
      canvas.restore();
      canvas.drawPath(
        path,
        _paint..color = SplashPainter.green.withValues(alpha: alpha),
      );
      canvas.restore();
    }
    _paint.style = PaintingStyle.fill;
  }

  /// A burst of paper from his chest when he lands (and a second one a little
  /// later): it goes up, turns over as it goes, and falls.
  void _confettiBurst() {
    final origin = _siuChest;
    for (final (pieces, after) in [
      (_confetti, 0.0),
      (_confetti2, _secondBurst),
    ]) {
      final age = ms - SplashTimeline.siuLand - after;
      if (age <= 0 || age > 1700) continue;
      _paint.style = PaintingStyle.fill;
      for (final c in pieces) {
        final t = (age - c.delay) / 1000;
        if (t <= 0 || t * 1000 >= c.life) continue;
        final life = t * 1000 / c.life;
        final x = origin.dx + math.cos(c.angle) * c.speed * t;
        final y =
            origin.dy + math.sin(c.angle) * c.speed * t + 0.5 * 380 * t * t;
        final alpha = seg(life, 0, 0.05) * (1 - seg(life, 0.62, 1));
        if (alpha <= 0) continue;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(c.turn + c.spin * t);
        canvas.scale(1, math.cos(c.flip * t + c.turn));
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: c.width,
            height: c.height,
          ),
          _paint..color = c.color.withValues(alpha: alpha),
        );
        canvas.restore();
      }
    }
  }

  /// Short lines round the top of his head while he shouts "Siuuu".
  void _shoutRays() {
    final start = SplashTimeline.siuLand - 30;
    final end = SplashTimeline.unformStart + 60;
    if (ms < start || ms > end) return;
    final rig = PlayerRig(_poseAt(ms), ground: Scene.ground, facing: _facing);
    if (rig.pose.shout < 0.5 || rig.pose.yaw < 1.2) return;
    // They come in with the shout and go when he stops.
    final strength =
        seg(ms, start, SplashTimeline.siuLand + 50, Curves.easeOut) *
        (1 - seg(ms, SplashTimeline.unformStart - 80, end));
    final pulse = 0.5 + 0.5 * math.sin(ms * 0.045);
    _paint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6
      ..color = SplashPainter.green.withValues(alpha: 0.9 * strength);
    for (var i = -3; i <= 3; i++) {
      final angle = -math.pi / 2 + i * 0.36;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final from = rig.head + dir * (PlayerRig.headRadius + 9 + 3 * pulse);
      final to = rig.head + dir * (PlayerRig.headRadius + 19 + 9 * pulse);
      canvas.drawLine(from, to, _paint);
    }
    _paint.style = PaintingStyle.fill;
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

  /// A soft green light behind him when he lands: it flashes, and stays a
  /// little while he shouts.
  void _glow() {
    const start = SplashTimeline.siuLand;
    const end = SplashTimeline.unformStart + 220;
    if (ms < start || ms > end) return;
    final burst = seg(ms, start, start + 700, Curves.easeOutCubic);
    final hold =
        seg(ms, start, start + 120) *
        (1 - seg(ms, SplashTimeline.unformStart - 100, end));
    final alpha = 0.12 * hold + 0.34 * math.pow(1 - burst, 1.5).toDouble();
    if (alpha <= 0.003) return;
    final center = _siuChest;
    final radius = 80 + 120 * burst;
    _paint
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          SplashPainter.green.withValues(alpha: alpha),
          SplashPainter.green.withValues(alpha: alpha * 0.45),
          SplashPainter.green.withValues(alpha: 0),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, _paint);
    _paint.shader = null;
  }

  /// The camera pushes in when something lands, and eases back; while he
  /// shouts it pushes in slowly. (A factor on the size of everything.)
  double _zoom() {
    var zoom = 1.0;
    for (final (at, amp) in [
      (SplashTimeline.strike, 0.02),
      (SplashTimeline.siuLand, 0.05),
      (SplashTimeline.land, 0.022),
    ]) {
      final d = ms - at;
      if (d < 0 || d > 800) continue;
      zoom += amp * seg(ms, at, at + 45, Curves.easeOut) * math.exp(-d / 170);
    }
    zoom +=
        0.02 *
        seg(ms, SplashTimeline.siuLand, SplashTimeline.siuLand + 260) *
        (1 -
            seg(
              ms,
              SplashTimeline.unformStart - 80,
              SplashTimeline.unformStart + 320,
              Curves.easeInOut,
            ));
    return zoom;
  }

  /// The whole scene shakes a little when something lands (units).
  Offset _shake() {
    var dx = 0.0;
    var dy = 0.0;
    for (final (at, amp) in [
      (SplashTimeline.strike, 2.5),
      (SplashTimeline.siuLand, 3.5),
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
