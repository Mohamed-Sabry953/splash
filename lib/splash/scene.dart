import 'dart:ui';

import 'logo_data.dart';

/// Where things are in the story. Everything is measured in the same units,
/// with (0, 0) in the middle of the screen, x to the right and y down; one unit
/// is a point of a 390 points wide phone.
abstract final class Scene {
  /// The logo is this wide, and in the middle.
  static const double logoWidth = 265;

  /// Logo units (the picture it was traced from) to scene units.
  static const double logoScale = logoWidth / kLogoWidth;

  /// Takes a point of the logo to where it is in the scene.
  static Offset fromLogo(Offset p) => Offset(
    (p.dx - kLogoWidth / 2) * logoScale,
    (p.dy - kLogoHeight / 2) * logoScale,
  );

  /// The ball in the logo: its middle and radius.
  static final Offset logoBall = fromLogo(const Offset(kBallCx, kBallCy));
  static const double logoBallRadius = kBallRadius * logoScale;

  /// The pitch: the height of the ground, and where the player stands.
  static const double ground = 96;
  static const double playerX = -50;

  /// The ball in the game is smaller than the one in the logo.
  static const double ballRadius = 13;
}
