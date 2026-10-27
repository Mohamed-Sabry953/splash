import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l3b_splash/splash/l3b_logo.dart';
import 'package:l3b_splash/splash/l3b_splash_screen.dart';
import 'package:l3b_splash/splash/logo_data.dart';
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

    test('at rest it is as big as it says, and the ball is a circle', () {
      final all = logo.all
          .map((p) => p.bounds)
          .reduce((a, b) => a.expandToInclude(b));
      // The picture the logo was traced from has a margin of a few pixels.
      expect(all.left, closeTo(0, 6));
      expect(all.top, closeTo(0, 6));
      expect(all.right, closeTo(kLogoWidth, 6));
      expect(all.bottom, closeTo(kLogoHeight, 6));

      // The patches fill a ball: none is further from its middle than its edge.
      for (final patch in logo.ball) {
        for (final corner in [patch.bounds.topLeft, patch.bounds.bottomRight]) {
          expect(
            (corner - L3bLogo.ballCenter).distance,
            lessThan(L3bLogo.ballRadius * 1.45),
          );
        }
      }
    });

    test('the filler is inside the ball and does not touch the 5', () {
      final fill = logo.ballFill;
      expect(
        fill.bounds.left,
        greaterThan(L3bLogo.ballCenter.dx - L3bLogo.ballRadius),
      );
      expect(
        fill.bounds.right,
        lessThanOrEqualTo(L3bLogo.ballCenter.dx + L3bLogo.ballRadius + 1),
      );
      // The 5 is pressed into where the filler was: it lies over it.
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
      expect(logo.swooshMiddleAt(5000), isNotNaN);
    });
  });

  group('the picture', () {
    test('is blank when it starts', () async {
      final pixels = await _pixels(
        await _draw((c, s) => const SplashPainter(ms: 0).paint(c, s)),
      );
      expect(pixels.where((v) => v != 255), isEmpty);
    });

    test('ends as the logo at rest, exactly where the splash put it', () async {
      const size = ui.Size(390, 844);
      final layout = SplashLayout.of(size);
      final end = await _pixels(
        await _draw(
          (c, s) => const SplashPainter(ms: SplashTimeline.total).paint(c, s),
        ),
      );
      final rest = await _pixels(
        await _draw((c, s) {
          c.translate(layout.origin.dx, layout.origin.dy);
          c.scale(layout.scale);
          L3bLogo.instance.paintRest(c);
        }),
      );
      var different = 0;
      for (var i = 0; i < end.length; i++) {
        if ((end[i] - rest[i]).abs() > 3) different++;
      }
      expect(different, 0);
    });

    test('has nothing left of the effects once the shine is over', () async {
      final a = await _pixels(
        await _draw(
          (c, s) =>
              const SplashPainter(ms: SplashTimeline.restAt + 1).paint(c, s),
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
        for (var ms = -100.0; ms <= SplashTimeline.total + 100; ms += 17) {
          final recorder = ui.PictureRecorder();
          SplashPainter(ms: ms).paint(ui.Canvas(recorder), size);
          recorder.endRecording().dispose();
        }
      }
    });

    test('the logo fits the width of a phone and stays on a tablet', () {
      final phone = SplashLayout.of(const ui.Size(390, 844));
      expect(kLogoWidth * phone.scale, closeTo(390 * 0.84, 0.01));
      final tablet = SplashLayout.of(const ui.Size(1024, 1366));
      expect(kLogoWidth * tablet.scale, closeTo(540, 0.01));
      // And it is in the middle, a little above.
      expect(
        phone.origin.dx * 2 + kLogoWidth * phone.scale,
        closeTo(390, 0.01),
      );
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
      await tester.pump(const Duration(milliseconds: 3300));
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
      await tester.pump(const Duration(milliseconds: 1600));
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

    testWidgets('gives a tap on the phone at each landing, in order', (
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
      for (var ms = 0; ms < 3500; ms += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(taps, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.lightImpact',
      ]);
    });

    testWidgets('does not fail on a phone that can not vibrate', (
      tester,
    ) async {
      // Nothing answers the call: it is what a phone without a motor does.
      await tester.pumpWidget(_app(L3bSplashScreen(onFinished: () {})));
      await tester.pump();
      for (var ms = 0; ms < 3500; ms += 100) {
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
