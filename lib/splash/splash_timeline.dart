import 'package:flutter/animation.dart';

/// When things happen in the splash, in milliseconds from its start. The
/// splash is a story told in a few beats: the ball is dribbled in and lands,
/// the 5 slams into the gap it left, its top bar shoots to the right, the
/// letters follow, and a shine sweeps over the logo.
abstract final class SplashTimeline {
  /// The whole splash, including the moment the logo is left alone.
  static const double total = 3400;

  // The ball.
  static const double ballStart = 120;
  static const double ballLand = 1150;

  /// The ball touches the ground three times, each hop lower than the last.
  static const List<double> hopStarts = [ballStart, 660, 960];
  static const List<double> hopEnds = [660, 960, ballLand];
  static const List<double> hopHeights = [250, 84, 26]; // logo units
  static const List<double> hopSquash = [0.20, 0.11, 0.07];

  // The 5.
  static const double fiveStart = 1250;
  static const double fiveEnd = 1770;

  /// About when the 5 lands in its place.
  static const double fiveImpact = 1390;

  // The stroke out of the 5.
  static const double swooshStart = 1560;
  static const double swooshEnd = 1990;

  // The letters, one after the other.
  static const double lettersStart = 1600;
  static const double letterGap = 105;
  static const double letterTime = 430;

  // The shine over the whole logo.
  static const double shineStart = 2250;
  static const double shineEnd = 2900;

  /// The splash only needs to wait this long after the shine to be at rest.
  static const double restAt = shineEnd;

  /// Things that can be felt: (when, what).
  static const List<(double, SplashBeat)> beats = [
    (ballLand, SplashBeat.ballLands),
    (fiveImpact, SplashBeat.fiveLands),
    (swooshStart + 20, SplashBeat.swoosh),
  ];
}

enum SplashBeat { ballLands, fiveLands, swoosh }

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
