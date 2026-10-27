import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';

import 'player.dart';
import 'scene.dart';
import 'splash_timeline.dart';

/// Where the ball is, and how it looks.
class BallState {
  const BallState({
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

/// Where the ball is at every moment of the story: it crouches and is thrown
/// up to the top of the screen, it falls on the foot of the player (who
/// kicks it over his head), it goes out of the screen to the right, and it
/// comes back in from the left, to the logo.
class BallTrack {
  const BallTrack({required this.halfWidth, required this.halfHeight});

  /// How far, in units, the screen goes left and right from the middle, and
  /// up and down.
  final double halfWidth;
  final double halfHeight;

  /// The player at the moment of the kick, and where the ball is then: just
  /// above the toe of the foot that kicks it over his head.
  static final PlayerRig strikeRig = PlayerRig(
    PlayerPoses.strike.copyWith(x: Scene.playerX + PlayerPoses.strike.x),
    ground: Scene.ground,
    facing: -1,
  );
  static final Offset contact =
      strikeRig.kickToe +
      const Offset(Scene.ballRadius * 0.55, -Scene.ballRadius * 0.85);

  /// How high the ball goes: near the top of the screen.
  Offset get apex => Offset(contact.dx - 16, -math.min(262.0, halfHeight - 90));

  // --- the shot -----------------------------------------------------------

  /// How fast the ball leaves the foot (units per second): to the right, a
  /// little up, and almost flat.
  static const Offset shotVelocity = Offset(720, -60);

  /// How much it falls on the way (units per second, squared).
  static const double shotGravity = 500;

  /// The ball after the kick, [tau] seconds on: it goes on to the right.
  static Offset shotAt(double tau) => Offset(
    contact.dx + shotVelocity.dx * tau,
    contact.dy + shotVelocity.dy * tau + 0.5 * shotGravity * tau * tau,
  );

  /// When, in milliseconds, the ball has gone out of the screen on the right.
  double get exit {
    final tau =
        (halfWidth + Scene.ballRadius * 2 - contact.dx) / shotVelocity.dx;
    return math.min(
      SplashTimeline.strike + tau * 1000,
      SplashTimeline.comeBack - 60,
    );
  }

  static Offset _bezier(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  // --- the whole way ------------------------------------------------------

  /// The ball [ms] milliseconds from the start of the splash.
  BallState at(double ms) {
    final rest = Scene.logoBall;
    const rLogo = Scene.logoBallRadius;
    const rGame = Scene.ballRadius;

    if (ms < SplashTimeline.launch) {
      // It crouches before it is thrown.
      final c = seg(
        ms,
        SplashTimeline.squash,
        SplashTimeline.launch,
        Curves.easeIn,
      );
      final sy = 1 - 0.16 * c;
      return BallState(
        center: rest + Offset(0, rLogo * (1 - sy)),
        radius: rLogo,
        sx: 1 + 0.12 * c,
        sy: sy,
        fill: 0,
      );
    }
    if (ms < SplashTimeline.apex) {
      final u =
          (ms - SplashTimeline.launch) /
          (SplashTimeline.apex - SplashTimeline.launch);
      final up = 1 - (1 - u) * (1 - u);
      final across = Curves.easeInOut.transform(u);
      final stretch = 1 + 0.2 * math.pow(1 - u, 2);
      return BallState(
        center: Offset(
          lerpDouble(rest.dx, apex.dx, across)!,
          lerpDouble(rest.dy, apex.dy, up)!,
        ),
        radius: lerpDouble(rLogo, rGame, Curves.easeOutCubic.transform(u))!,
        spin: math.pi * 6 * Curves.easeOut.transform(u),
        sx: 1 / math.sqrt(stretch),
        sy: stretch,
        fill: seg(
          ms,
          SplashTimeline.launch,
          SplashTimeline.launch + 70,
          Curves.easeOut,
        ),
      );
    }
    const turns = math.pi * 6;
    if (ms < SplashTimeline.strike) {
      // It falls on the foot of the player.
      final u =
          (ms - SplashTimeline.apex) /
          (SplashTimeline.strike - SplashTimeline.apex);
      return BallState(
        center: Offset(
          lerpDouble(apex.dx, contact.dx, Curves.easeInOut.transform(u))!,
          lerpDouble(apex.dy, contact.dy, u * u)!,
        ),
        radius: rGame,
        spin: turns + 3.2 * (ms - SplashTimeline.apex) / 1000,
      );
    }
    final spinAtKick =
        turns + 3.2 * (SplashTimeline.strike - SplashTimeline.apex) / 1000;
    if (ms < exit) {
      final tau = (ms - SplashTimeline.strike) / 1000;
      return BallState(
        center: shotAt(tau),
        radius: rGame,
        spin: spinAtKick + 24 * tau,
      );
    }
    if (ms < SplashTimeline.comeBack) {
      // Out of the screen, on the right.
      return BallState(
        center: Offset(halfWidth + 300, Scene.ground - 40),
        radius: rGame,
      );
    }
    if (ms < SplashTimeline.land) {
      // It comes in from the left, high, and falls on the logo, growing as it
      // comes near.
      final u =
          (ms - SplashTimeline.comeBack) /
          (SplashTimeline.land - SplashTimeline.comeBack);
      final e = math.pow(u, 1.6).toDouble();
      final from = Offset(-halfWidth - Scene.ballRadius * 4, -120);
      final control = Offset(-halfWidth * 0.6, -230);
      return BallState(
        center: _bezier(from, control, rest, e),
        radius: lerpDouble(rGame, rLogo, Curves.easeIn.transform(u))!,
        spin: lerpDouble(math.pi * 4, 0, e)!,
      );
    }
    // At home: it squashes a little as it settles.
    final d = ms - SplashTimeline.land;
    final squash = 0.17 * math.exp(-math.pow(d / 70, 2));
    final sy = 1 - squash;
    return BallState(
      center: rest + Offset(0, rLogo * (1 - sy)),
      radius: rLogo,
      sx: 1 + 0.8 * squash,
      sy: sy,
      fill: 1 - seg(ms, SplashTimeline.land + 10, SplashTimeline.land + 40),
    );
  }
}
