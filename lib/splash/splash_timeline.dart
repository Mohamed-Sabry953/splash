import 'package:flutter/animation.dart';

/// When things happen in the splash, in milliseconds from its start.
///
/// The logo shows. The ball is thrown up; the letters turn into dust, and the
/// dust into a player; the player kicks the ball out of the screen with a
/// bicycle kick and celebrates like Ronaldo ("Siuuu"); then the player turns
/// back into the letters, the ball comes home from the other side, and a shine
/// goes over the logo.
abstract final class SplashTimeline {
  static const double total = 5550;

  /// The logo comes in.
  static const double logoIn = 300;

  // The ball.
  static const double squash = 610; // it crouches...
  static const double launch = 750; // ...and is thrown up
  static const double apex = 1490; // as high as it goes
  static const double strike = 1900; // the player's foot meets it
  static const double comeBack = 3860; // it comes back in from the left
  static const double land = 4320; // and is home

  // The letters become the player.
  static const double formStart = 890;
  static const double formEnd = 1510;

  // The player's moves: down, up, over backwards, the kick, down on his back,
  // up again, and the celebration of Ronaldo: a crouch, a jump with a turn in
  // the air, and a landing facing us with the arms and legs wide.
  static const double crouch = 1610;
  static const double takeOff = 1710;
  static const double scissors = 1810;
  static const double fall = 2010;
  static const double lying = 2120;
  static const double getUp = 2170;
  static const double siuCrouch = 2300;
  static const double siuJump = 2360;
  static const double siuPeak = 2540;
  static const double siuLand = 2720; // "Siuuu"
  static const double siuSettle = 2890; // the knees are straight again

  // The player becomes the letters.
  static const double unformStart = 3640; // (he shouts for a moment first)
  static const double unformEnd = 4300;

  // The shine over the logo.
  static const double shineStart = 4400;
  static const double shineEnd = 4980;

  /// Things that can be felt: (when, what).
  static const List<(double, SplashBeat)> beats = [
    (launch, SplashBeat.thrown),
    (strike, SplashBeat.kick),
    (siuLand, SplashBeat.siu),
    (land, SplashBeat.home),
  ];
}

enum SplashBeat { thrown, kick, siu, home }

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
