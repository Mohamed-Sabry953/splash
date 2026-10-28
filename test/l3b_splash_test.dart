import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l3b_splash/splash/ball_track.dart';
import 'package:l3b_splash/splash/l3b_logo.dart';
import 'package:l3b_splash/splash/l3b_splash_screen.dart';
import 'package:l3b_splash/splash/logo_data.dart';
import 'package:l3b_splash/splash/player.dart';
import 'package:l3b_splash/splash/scene.dart';
import 'package:l3b_splash/splash/siu_text.dart';
import 'package:l3b_splash/splash/splash_dust.dart';
import 'package:l3b_splash/splash/splash_painter.dart';
import 'package:l3b_splash/splash/splash_timeline.dart';

Future<ui.Image> _draw(
  void Function(ui.Canvas canvas, ui.Size size) paint, {
  ui.Size size = const ui.Size(390, 844),
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(Colors.white, BlendMode.src);
  paint(canvas, size);
  return recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
}

Future<Uint8List> _pixels(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

Widget _app(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: child,
    ),
  );
}

void main() {
  group('the logo', () {
    final logo = L3bLogo.instance;

    test('is cut into the pieces that move on their own', () {
      expect(logo.ball, hasLength(9));
      expect(logo.letters.map((p) => p.name), ['L', '3', 'B']);
      expect(logo.five.name, 'five');
      expect(logo.swoosh.name, 'swoosh');
      for (final piece in [...logo.all, logo.ballFill]) {
        expect(piece.bounds.isEmpty, isFalse, reason: piece.name);
      }
    });

    test('at rest it is as big as it says', () {
      final all = logo.all
          .map((p) => p.bounds)
          .reduce((a, b) => a.expandToInclude(b));
      // The picture the logo was traced from has a margin of a few pixels.
      expect(all.left, closeTo(0, 6));
      expect(all.top, closeTo(0, 6));
      expect(all.right, closeTo(kLogoWidth, 6));
      expect(all.bottom, closeTo(kLogoHeight, 6));
    });

    test('the filler is a piece of the ball that the 5 covers', () {
      final fill = logo.ballFill;
      expect(
        fill.bounds.right,
        lessThanOrEqualTo(L3bLogo.ballCenter.dx + L3bLogo.ballRadius + 1),
      );
      expect(fill.bounds.overlaps(logo.five.bounds), isTrue);
    });

    test('knows where the middle of the stroke is', () {
      final swoosh = logo.swoosh.bounds;
      for (final x in [330.0, 600.0, 900.0, 1100.0]) {
        final y = logo.swooshMiddleAt(x);
        expect(y, inInclusiveRange(swoosh.top, swoosh.bottom), reason: 'x=$x');
        expect(logo.swoosh.path.contains(Offset(x, y)), isTrue, reason: 'x=$x');
      }
      expect(logo.swooshMiddleAt(-50), logo.swooshMiddleAt(0));
    });
  });

  group('the player', () {
    PlayerRig rigOf(PlayerPose pose) => PlayerRig(
      pose.copyWith(x: Scene.playerX + pose.x),
      ground: Scene.ground,
      facing: -1,
    );

    test(
      'stands on the ground when he stands, and is in the air when lifted',
      () {
        for (final pose in [
          PlayerPoses.ready,
          PlayerPoses.crouch,
          PlayerPoses.siuLand,
          PlayerPoses.siu,
        ]) {
          final rig = rigOf(pose);
          expect(
            rig.plantAnkle.dy,
            closeTo(Scene.ground - PlayerRig.ankleHeight, 0.01),
          );
          expect(
            rig.plantToe.dy,
            closeTo(rig.plantAnkle.dy, 0.01),
          ); // flat foot
          expect(
            rigOf(pose.copyWith(lift: 20)).plantAnkle.dy,
            closeTo(Scene.ground - PlayerRig.ankleHeight - 20, 0.01),
          );
        }
      },
    );

    test('is a person: about 170 units tall, head on top', () {
      final rig = rigOf(PlayerPoses.ready);
      final height = Scene.ground - (rig.head.dy - PlayerRig.headRadius);
      expect(height, inInclusiveRange(150, 190));
      expect(rig.head.dy, lessThan(rig.shoulder.dy));
      expect(rig.shoulder.dy, lessThan(rig.hip.dy));
    });

    test('faces left: his feet and his face are to the left of the hip', () {
      final rig = rigOf(PlayerPoses.crouch);
      expect(rig.kickToe.dx, lessThan(rig.hip.dx));
      expect(rig.head.dx, lessThan(rig.hip.dx));
    });

    test('kicks over his head: flat in the air, the leg straight up', () {
      final rig = rigOf(PlayerPoses.strike);
      // The body is flat: the head is at the height of the hip, further
      // towards where the ball goes, and the leg that kicks is above them both.
      expect((rig.head.dy - rig.hip.dy).abs(), lessThan(30));
      expect(rig.head.dx, greaterThan(rig.hip.dx + 40));
      expect(rig.kickToe.dy, lessThan(rig.hip.dy - 70));
      expect((rig.kickToe.dx - rig.hip.dx).abs(), lessThan(30));
      // And he is in the air.
      expect(rig.hip.dy, lessThan(Scene.ground - 100));
    });

    test('lies on the ground on his back, not under it', () {
      final rig = rigOf(PlayerPoses.lying);
      for (final point in [
        rig.hip,
        rig.head,
        rig.nearHand,
        rig.farHand,
        rig.kickAnkle,
        rig.plantAnkle,
      ]) {
        expect(point.dy, lessThanOrEqualTo(Scene.ground + 0.5));
      }
      expect((rig.head.dy - rig.hip.dy).abs(), lessThan(30));
    });

    test('every part has something to paint, and the shirt is green', () {
      final rig = rigOf(PlayerPoses.ready);
      expect(rig.parts, isNotEmpty);
      final chest = Offset.lerp(rig.hip, rig.shoulder, 0.5)!;
      expect(rig.partAt(chest)?.role, BodyRole.shirt);
      expect(
        rig.partAt(rig.head + const Offset(-3, 3))?.role,
        anyOf(BodyRole.skin, BodyRole.hair),
      );
      expect(rig.partAt(const Offset(-500, -500)), isNull);
      expect(PlayerRig.isGreen(BodyRole.sock), isTrue);
      expect(PlayerRig.isGreen(BodyRole.skin), isFalse);
    });

    test('is whole in every pose: nothing is missing or in the wrong place', () {
      for (final pose in [
        PlayerPoses.ready,
        PlayerPoses.crouch,
        PlayerPoses.takeOff,
        PlayerPoses.scissors,
        PlayerPoses.strike,
        PlayerPoses.fall,
        PlayerPoses.lying,
        PlayerPoses.siuAir,
        PlayerPoses.siuLand,
        PlayerPoses.siu,
      ]) {
        final rig = rigOf(pose);
        for (final part in rig.parts) {
          final bounds = part.path.getBounds();
          expect(bounds.isEmpty, isFalse);
          expect(bounds.width.isFinite && bounds.height.isFinite, isTrue);
        }
        // Seen from the side the joints are where the lengths of the body say.
        if (pose.yaw == 0 && pose.kickSide == 0) {
          expect(
            (rig.kickKnee - rig.hip).distance,
            closeTo(PlayerRig.thigh, 0.01),
          );
          expect(
            (rig.kickAnkle - rig.kickKnee).distance,
            closeTo(PlayerRig.shin, 0.01),
          );
          expect(
            (rig.plantKnee - rig.hip).distance,
            closeTo(PlayerRig.thigh, 0.01),
          );
          expect(
            (rig.nearHand - rig.nearElbow).distance,
            closeTo(PlayerRig.foreArm, 0.01),
          );
        }
      }
    });

    test('"Siuuu": faces us, legs wide, arms down and out, mouth open', () {
      final rig = rigOf(PlayerPoses.siu);
      // Both feet are on the ground, on both sides of the hip, as far from it.
      expect(rig.kickAnkle.dy, closeTo(rig.plantAnkle.dy, 0.01));
      expect(
        (rig.kickAnkle.dx - rig.hip.dx) * (rig.plantAnkle.dx - rig.hip.dx),
        lessThan(0),
      );
      expect(
        (rig.kickAnkle.dx - rig.hip.dx).abs(),
        closeTo((rig.plantAnkle.dx - rig.hip.dx).abs(), 0.01),
      );
      expect((rig.kickAnkle.dx - rig.plantAnkle.dx).abs(), greaterThan(55));
      // The arms are out on both sides, lower than the shoulders.
      expect(
        (rig.nearHand.dx - rig.hip.dx) * (rig.farHand.dx - rig.hip.dx),
        lessThan(0),
      );
      expect((rig.nearHand.dx - rig.farHand.dx).abs(), greaterThan(70));
      expect(rig.nearHand.dy, greaterThan(rig.shoulder.dy + 20));
      expect(rig.farHand.dy, greaterThan(rig.shoulder.dy + 20));
      // The head is over the middle of the body, and the mouth is on it.
      expect((rig.head.dx - rig.hip.dx).abs(), lessThan(8));
      expect((rig.mouth - rig.head).distance, lessThan(PlayerRig.headRadius));
      expect(rig.mouth.dy, greaterThan(rig.head.dy - 4));
      // He is a body seen from the front, not a line.
      final silhouette = rig.parts
          .map((p) => p.path.getBounds())
          .reduce((a, b) => a.expandToInclude(b));
      expect(silhouette.width, greaterThan(80));
    });

    test(
      '"Siuuu" is in the middle of the screen; he lands with bent knees',
      () {
        final land = rigOf(PlayerPoses.siuLand);
        final stand = rigOf(PlayerPoses.siu);
        expect(stand.hip.dx, closeTo(0, 0.01));
        expect(land.hip.dx, closeTo(0, 0.01));
        // The knees take the landing: the hip is lower, and he is no taller
        // than when he stands.
        expect(land.hip.dy, greaterThan(stand.hip.dy + 2));
        expect(land.head.dy, greaterThan(stand.head.dy));
      },
    );

    test('turns from the side to the front: wider and wider', () {
      var last = -1.0;
      for (final yaw in [0.0, 0.4, 0.8, 1.2, 1.5707963267948966]) {
        final rig = PlayerRig(
          PlayerPoses.siu.withYaw(yaw),
          ground: Scene.ground,
          facing: -1,
        );
        final width = (rig.nearHand.dx - rig.farHand.dx).abs();
        expect(width, greaterThan(last - 0.001), reason: 'yaw=$yaw');
        last = width;
      }
    });

    test('the ball is where the foot meets it: above the toe', () {
      final strike = rigOf(PlayerPoses.strike);
      final contact =
          strike.kickToe +
          const Offset(Scene.ballRadius * 0.55, -Scene.ballRadius * 0.85);
      expect(contact.dy, lessThan(strike.kickToe.dy));
      expect(
        (contact - strike.kickToe).distance,
        lessThan(Scene.ballRadius * 1.5),
      );
    });
  });

  group('the ball', () {
    const half = 195.0;
    const track = BallTrack(halfWidth: half, halfHeight: 422);

    test('is thrown up to near the top of the screen, without leaving it', () {
      var last = track.at(SplashTimeline.launch).center.dy;
      for (
        var ms = SplashTimeline.launch + 20;
        ms <= SplashTimeline.apex;
        ms += 20
      ) {
        final y = track.at(ms).center.dy;
        expect(y, lessThanOrEqualTo(last + 0.001), reason: 'rising at $ms');
        last = y;
      }
      final top = track.at(SplashTimeline.apex);
      expect(top.center.dy - top.radius, greaterThan(-422));
      expect(top.center.dy, lessThan(-200));
      // It gets smaller as it goes, and it is whole.
      expect(top.radius, Scene.ballRadius);
      expect(top.fill, 1);
    });

    test('falls on the foot at the kick, over the head of the player', () {
      final at = track.at(SplashTimeline.strike);
      expect((at.center - BallTrack.contact).distance, lessThan(0.5));
      final head = BallTrack.strikeRig.head;
      expect(at.center.dy, lessThan(head.dy - 40));
    });

    test('is kicked to the right, high over the player, and does not turn', () {
      var last = track.at(SplashTimeline.strike).center;
      for (var ms = SplashTimeline.strike + 10; ms < track.exit; ms += 10) {
        final now = track.at(ms).center;
        // To the right every moment, and never down to the player or the pitch.
        expect(now.dx, greaterThan(last.dx), reason: 'ms=$ms');
        expect(now.dy, lessThan(Scene.ground - 100), reason: 'ms=$ms');
        last = now;
      }
    });

    test('goes out of the screen on the right, and stays out', () {
      for (final width in [160.0, 195.0, 260.0, 341.0, 400.0]) {
        final t = BallTrack(halfWidth: width, halfHeight: 400);
        expect(t.exit, lessThan(SplashTimeline.comeBack));
        // It is still in the screen before, and gone after.
        final before = t.at(SplashTimeline.strike + 60);
        expect(before.center.dx - before.radius, lessThan(width));
        for (var ms = t.exit; ms < SplashTimeline.comeBack; ms += 25) {
          final s = t.at(ms);
          expect(
            s.center.dx - s.radius,
            greaterThan(width),
            reason: 'w=$width ms=$ms',
          );
        }
      }
    });

    test('comes back in from the left, and falls on the logo', () {
      final start = track.at(SplashTimeline.comeBack);
      expect(start.center.dx + start.radius, lessThan(-half));

      // It moves to the right all the way, and appears at the left edge.
      var last = start.center.dx;
      var entered = false;
      for (
        var ms = SplashTimeline.comeBack;
        ms <= SplashTimeline.land;
        ms += 10
      ) {
        final s = track.at(ms);
        expect(
          s.center.dx,
          greaterThanOrEqualTo(last - 0.001),
          reason: 'ms=$ms',
        );
        last = s.center.dx;
        if (!entered && s.center.dx + s.radius > -half) {
          entered = true;
          expect(s.center.dx, lessThan(-half + 3 * s.radius));
        }
      }
      expect(entered, isTrue);

      // And it is the ball of the logo, as the logo has it.
      final home = track.at(SplashTimeline.land + 400);
      expect((home.center - Scene.logoBall).distance, lessThan(0.01));
      expect(home.radius, Scene.logoBallRadius);
      expect(home.spin % (2 * 3.141592653589793), closeTo(0, 0.001));
      expect(home.fill, 0);
    });

    test('is never in two places: no jumps from one moment to the next', () {
      var last = track.at(0).center;
      for (var ms = 5.0; ms <= SplashTimeline.total; ms += 5) {
        final now = track.at(ms).center;
        final jump = (now - last).distance;
        // Going off the right and coming in from the left is the one thing
        // that is allowed to jump: it happens out of sight.
        if (ms > track.exit && ms <= SplashTimeline.comeBack + 5) {
          last = now;
          continue;
        }
        expect(jump, lessThan(60), reason: 'jump of $jump at $ms ms');
        last = now;
      }
    });
  });

  group('the dust', () {
    test('has the same dots going and coming, and a lot of them', () {
      final dust = SplashDust.instance;
      expect(dust.forward.count, greaterThan(800));
      expect(dust.reverse.count, dust.forward.count);
    });

    test('starts on the letters and ends on the player', () {
      final logo = L3bLogo.instance;
      final toScene = Matrix4.identity()
        ..scaleByDouble(Scene.logoScale, Scene.logoScale, 1, 1)
        ..translateByDouble(-kLogoWidth / 2, -kLogoHeight / 2, 0, 1);
      final letters = [
        for (final p in [logo.five, logo.swoosh, ...logo.letters])
          p.path.transform(toScene.storage),
      ];
      final rig = PlayerRig(
        PlayerPoses.ready.copyWith(x: Scene.playerX + PlayerPoses.ready.x),
        ground: Scene.ground,
        facing: -1,
      );
      final forward = SplashDust.instance.forward;
      var onLetters = 0;
      var onPlayer = 0;
      for (var i = 0; i < forward.count; i++) {
        final from = Offset(forward.from[i * 2], forward.from[i * 2 + 1]);
        final to = Offset(forward.to[i * 2], forward.to[i * 2 + 1]);
        if (letters.any((l) => l.contains(from))) onLetters++;
        if (rig.partAt(to) != null) onPlayer++;
      }
      expect(onLetters / forward.count, greaterThan(0.99));
      // A few dots sit a hair outside the edge: they were jittered.
      expect(onPlayer / forward.count, greaterThan(0.9));
    });

    test('takes the green dust to the shirt', () {
      final forward = SplashDust.instance.forward;
      var greenToShirt = 0;
      var green = 0;
      for (var i = 0; i < forward.count; i++) {
        // The colors are kept as signed numbers.
        if (forward.colorFrom[i].toUnsigned(32) == 0xFF8DC641) {
          green++;
          final to = forward.colorTo[i].toUnsigned(32);
          if (to == 0xFF8DC641 || to == 0xFF6FA52E) {
            greenToShirt++;
          }
        }
      }
      expect(green, greaterThan(100));
      expect(greenToShirt, green);
    });
  });

  group('the picture', () {
    test('is blank when it starts', () async {
      final pixels = await _pixels(
        await _draw((c, s) => const SplashPainter(ms: 0).paint(c, s)),
      );
      expect(pixels.where((v) => v != 255), isEmpty);
    });

    test('shows only the logo, in the middle, once it has come in', () async {
      final pixels = await _pixels(
        await _draw((c, s) => const SplashPainter(ms: 360).paint(c, s)),
      );
      // Nothing near the top or the bottom of the screen: just the logo.
      const width = 390;
      for (final row in [0, 100, 300, 560, 700, 843]) {
        for (var x = 0; x < width; x++) {
          expect(pixels[(row * width + x) * 4], 255, reason: 'row $row');
        }
      }
      // And something in the middle row.
      var ink = 0;
      for (var x = 0; x < width; x++) {
        if (pixels[(422 * width + x) * 4] != 255) ink++;
      }
      expect(ink, greaterThan(60));
    });

    test('ends as the logo at rest, in the middle of the screen', () async {
      const size = ui.Size(390, 844);
      final layout = SplashLayout.of(size);
      final end = await _pixels(
        await _draw(
          (c, s) => const SplashPainter(ms: SplashTimeline.total).paint(c, s),
        ),
      );
      final rest = await _pixels(
        await _draw((c, s) {
          c.translate(layout.center.dx, layout.center.dy);
          c.scale(layout.scale * Scene.logoScale);
          c.translate(-kLogoWidth / 2, -kLogoHeight / 2);
          L3bLogo.instance.paintRest(c);
        }),
      );
      var different = 0;
      for (var i = 0; i < end.length; i++) {
        if ((end[i] - rest[i]).abs() > 3) different++;
      }
      expect(different, 0);
    });

    test('the 5 is whole and in front when the ball has landed', () async {
      // A point well inside the 5, where the ball is under it.
      final five = L3bLogo.instance.five;
      Offset? inside;
      for (
        var y = five.bounds.top;
        y < five.bounds.bottom && inside == null;
        y += 4
      ) {
        for (var x = five.bounds.left; x < five.bounds.right; x += 4) {
          final p = Offset(x, y);
          const margin = 14.0;
          if ([
                p,
                p + const Offset(margin, 0),
                p - const Offset(margin, 0),
                p + const Offset(0, margin),
                p - const Offset(0, margin),
              ].every(five.path.contains) &&
              L3bLogo.instance.ball.any(
                (b) => (b.bounds.inflate(60)).contains(p),
              ) &&
              (p - L3bLogo.ballCenter).distance < L3bLogo.ballRadius) {
            inside = p;
            break;
          }
        }
      }
      expect(inside, isNotNull);
      const size = ui.Size(390, 844);
      final layout = SplashLayout.of(size);
      final at = Offset(
        layout.center.dx +
            (inside!.dx - kLogoWidth / 2) * Scene.logoScale * layout.scale,
        layout.center.dy +
            (inside.dy - kLogoHeight / 2) * Scene.logoScale * layout.scale,
      );
      final image = await _draw(
        (c, s) => SplashPainter(ms: SplashTimeline.land + 60).paint(c, s),
      );
      final pixels = await _pixels(image);
      final i = (at.dy.round() * size.width.round() + at.dx.round()) * 4;
      // The green of the 5, not the navy of the ball or a mix of the two.
      expect(pixels[i], closeTo(0x8D, 4));
      expect(pixels[i + 1], closeTo(0xC6, 4));
      expect(pixels[i + 2], closeTo(0x41, 4));
    });

    test('has nothing left of the effects once the shine is over', () async {
      final a = await _pixels(
        await _draw(
          (c, s) => const SplashPainter(
            ms: SplashTimeline.shineEnd + 240,
          ).paint(c, s),
        ),
      );
      final b = await _pixels(
        await _draw(
          (c, s) => const SplashPainter(ms: SplashTimeline.total).paint(c, s),
        ),
      );
      expect(a, b);
    });

    test('can be painted at any moment, on any screen', () async {
      const screens = [
        ui.Size(390, 844),
        ui.Size(320, 480),
        ui.Size(1024, 768),
        ui.Size(844, 390),
        ui.Size(10, 10),
        ui.Size.zero,
      ];
      for (final size in screens) {
        for (var ms = -100.0; ms <= SplashTimeline.total + 100; ms += 23) {
          final recorder = ui.PictureRecorder();
          SplashPainter(ms: ms).paint(ui.Canvas(recorder), size);
          recorder.endRecording().dispose();
        }
      }
    });

    test('the logo is a part of the width of the screen, in the middle', () {
      final phone = SplashLayout.of(const ui.Size(390, 844));
      expect(Scene.logoWidth * phone.scale, closeTo(265, 0.01));
      expect(phone.center, const Offset(195, 422));
      final tablet = SplashLayout.of(const ui.Size(1024, 1366));
      expect(tablet.scale, 1.5);
      final small = SplashLayout.of(const ui.Size(320, 568));
      expect(small.scale, lessThan(1));
      // The ball goes high on a phone, and not out of a short screen.
      expect(small.halfHeight, greaterThan(250));
    });
  });

  group('the word SIUUU', () {
    test('has a letter for each of its five letters, standing on the line', () {
      expect(SiuText.word, 'SIUUU');
      for (var i = 0; i < SiuText.word.length; i++) {
        final high = SiuText.height * SiuText.growth[i];
        // (the bounds of a path with arcs are not tight: look along the line)
        Rect? bounds;
        for (final metric in SiuText.letter(
          SiuText.word[i],
          high,
        ).computeMetrics()) {
          for (var d = 0.0; d <= metric.length; d += 0.25) {
            final p = metric.getTangentForOffset(d)!.position;
            final box = Rect.fromLTRB(p.dx, p.dy, p.dx, p.dy);
            bounds = bounds == null ? box : bounds.expandToInclude(box);
          }
        }
        bounds!;
        final w = SiuText.widthOf(SiuText.word[i]);
        // The line of the letter is inside the box of the letter: the pen
        // (half of it on each side) does not go past the box either.
        expect(bounds.left, greaterThanOrEqualTo(SiuText.stroke / 2 - 0.05));
        expect(bounds.right, lessThanOrEqualTo(w - SiuText.stroke / 2 + 0.05));
        expect(bounds.bottom, lessThanOrEqualTo(0.05));
        // The Is and the Us go up to the top; the S is a line that the pen
        // takes up to the top.
        expect(
          bounds.top,
          inInclusiveRange(-high - 0.05, -high + SiuText.stroke / 2 + 0.05),
        );
      }
    });

    test('the Us grow as the shout goes on, and the word has a width', () {
      expect(SiuText.growth.last, greaterThan(SiuText.growth.first));
      final widths = [
        for (final c in SiuText.word.split('')) SiuText.widthOf(c),
      ];
      expect(
        SiuText.width,
        closeTo(
          widths.reduce((a, b) => a + b) + SiuText.gap * (widths.length - 1),
          0.001,
        ),
      );
      // It fits in the width of a small phone with room to spare.
      expect(SiuText.width, lessThan(120));
    });
  });

  group('the splash screen', () {
    testWidgets('says it is done once, when the logo has rested', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(
        _app(L3bSplashScreen(haptics: false, onFinished: () => done++)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5450));
      expect(done, 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(done, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(done, 1);
    });

    testWidgets('can be played faster', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _app(
          L3bSplashScreen(haptics: false, speed: 2, onFinished: () => done++),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2675));
      expect(done, 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(done, 1);
    });

    testWidgets('with reduced motion shows the logo and moves on soon', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(
        _app(
          L3bSplashScreen(haptics: false, onFinished: () => done++),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      expect(done, 0);
      // Nothing is moving: it is the last picture from the first frame.
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
      expect((paint.painter! as SplashPainter).ms, SplashTimeline.total);
      await tester.pump(const Duration(milliseconds: 800));
      expect(done, 1);
    });

    testWidgets('can be taken away while it plays', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _app(L3bSplashScreen(haptics: true, onFinished: () => done++)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump(const Duration(seconds: 5));
      expect(done, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is read as the name of the team', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(L3bSplashScreen(haptics: false, onFinished: () {})),
      );
      expect(find.bySemanticsLabel('5L3B'), findsOneWidget);
      semantics.dispose();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('gives a tap on the phone at each beat, in order', (
      tester,
    ) async {
      final taps = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            taps.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(_app(L3bSplashScreen(onFinished: () {})));
      await tester.pump();
      for (var ms = 0; ms < 5600; ms += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(taps, [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
    });

    testWidgets('does not fail on a phone that can not vibrate', (
      tester,
    ) async {
      // Nothing answers the call: it is what a phone without a motor does.
      await tester.pumpWidget(_app(L3bSplashScreen(onFinished: () {})));
      await tester.pump();
      for (var ms = 0; ms < 5600; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the logo at rest fits any width it is given', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: L3bLogoView(width: 200))),
      ),
    );
    final size = tester.getSize(find.byType(L3bLogoView));
    expect(size.width, 200);
    expect(size.height, closeTo(200 * kLogoHeight / kLogoWidth, 0.01));
  });
}
