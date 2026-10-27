import 'package:flutter/animation.dart';

/// When things happen in the splash, in milliseconds from its start.
///
/// The logo shows. The ball is thrown up; the letters turn into dust, and the
/// dust into a player; the player kicks the ball into the goal and cheers;
/// then the player turns back into the letters, the ball comes home, and a
/// shine goes over the logo.
abstract final class SplashTimeline {
  static const double total = 3900;

  /// The logo comes in.
  static const double logoIn = 300;

  // The ball.
  static const double squash = 360; // it crouches...
  static const double launch = 500; // ...and is thrown up
  static const double apex = 1240; // as high as it goes
  static const double strike = 1650; // the player's foot meets it
  static const double goal = 1930; // it reaches the net
  static const double comeBack = 2340; // it leaves the net, for the logo
  static const double land = 2960; // and is home

  // The letters become the player.
  static const double formStart = 640;
  static const double formEnd = 1260;

  // The player's moves: down, up, over backwards, the kick, down on his back
  // and up again, cheering.
  static const double crouch = 1360;
  static const double takeOff = 1460;
  static const double scissors = 1560;
  static const double fall = 1760;
  static const double lying = 1870;
  static const double getUp = 1990;
  static const double cheer = 2200;

  // The player becomes the letters.
  static const double unformStart = 2260;
  static const double unformEnd = 2940;

  // The shine over the logo.
  static const double shineStart = 3040;
  static const double shineEnd = 3620;

  /// Things that can be felt: (when, what).
  static const List<(double, SplashBeat)> beats = [
    (launch, SplashBeat.thrown),
    (strike, SplashBeat.kick),
    (goal, SplashBeat.goal),
    (land, SplashBeat.home),
  ];
}

enum SplashBeat { thrown, kick, goal, home }

/// [t] mapped from [a, b] to 0..1 and then through [curve]; 0 before [a] and
/// 1 after [b].
double seg(double t, double a, double b, [Curve curve = Curves.linear]) {
  return curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
}

/// A bump that rises to 1 in [rise] ms from [at] and falls again over [fall].
double bump(double t, double at, double rise, double fall) {
  final d = t - at;
  if (d < -rise || d > fall) return 0;
  return d < 0
      ? Curves.easeOut.transform(1 + d / rise)
      : Curves.easeIn.transform(1 - d / fall);
}
