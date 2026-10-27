import 'package:flutter/widgets.dart' show Matrix4;

import 'l3b_logo.dart';
import 'logo_data.dart';
import 'morph.dart';
import 'player.dart';
import 'scene.dart';

/// The dust that carries the letters to the player, and the player back to
/// the letters. It takes a moment to make (thousands of points are tried in
/// the shapes), so it is made once, before the splash starts.
class SplashDust {
  SplashDust._(this.forward, this.reverse);

  /// The letters turning into the player when he is ready to kick.
  final DustMorph forward;

  /// The player, cheering, turning back into the letters.
  final DustMorph reverse;

  static final SplashDust instance = SplashDust._build();

  /// Makes the dust now, if it has not been made.
  static void prepare() => instance;

  static SplashDust _build() {
    final logo = L3bLogo.instance;
    final toScene = Matrix4.identity()
      ..scaleByDouble(Scene.logoScale, Scene.logoScale, 1, 1)
      ..translateByDouble(-kLogoWidth / 2, -kLogoHeight / 2, 0, 1);
    DustShape text(LogoPiece piece, int role) =>
        DustShape(piece.path.transform(toScene.storage), piece.color, role);
    final letters = [
      text(logo.five, 0),
      text(logo.swoosh, 0),
      for (final letter in logo.letters) text(letter, 1),
    ];

    List<DustShape> player(PlayerPose pose) {
      // He has his back to where the ball goes.
      final rig = PlayerRig(
        pose.copyWith(x: Scene.playerX + pose.x),
        ground: Scene.ground,
        facing: -1,
      );
      return [
        // (white dust would not be seen on the white screen: no teeth)
        for (final part in rig.parts)
          if (!PlayerRig.isDetail(part.role))
            DustShape(
              part.path,
              rig.colorOf(part.role),
              PlayerRig.isGreen(part.role) ? 0 : 1,
            ),
      ];
    }

    // The distance between the dots of the letters.
    const step = 5 * Scene.logoScale;
    return SplashDust._(
      DustMorph.between(
        from: letters,
        to: player(PlayerPoses.ready),
        step: step,
        fromIsText: true,
        seed: 3,
      ),
      DustMorph.between(
        from: player(PlayerPoses.siu),
        to: letters,
        step: step,
        fromIsText: false,
        seed: 4,
      ),
    );
  }
}
