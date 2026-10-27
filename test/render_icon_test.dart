import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:l3b_splash/splash/l3b_logo.dart';

/// Draws the mark of the logo (the ball and the 5, with a short stroke) as the
/// two big pictures that `tool/make_icons.py` makes the app icons from, into
/// the folder `L3B_ICON_DIR` (a development aid; does nothing without it):
///
///   L3B_ICON_DIR=tool flutter test test/render_icon_test.dart
///   python tool/make_icons.py
///
/// `app_icon_full.png` is the whole icon (the mark on white) and
/// `app_icon_foreground.png` the mark alone on nothing, smaller, for the
/// adaptive icon of Android (which keeps only the middle of it).
void main() {
  final dir = Platform.environment['L3B_ICON_DIR'];

  const size = 2048;

  /// The stroke of the 5 is shortened to just past the 5.
  const swooshFrom = 314.0;
  const swooshShrink = 0.2;

  Future<void> render(
    String name, {
    required bool white,
    required double fraction,
    required bool byWidth,
  }) async {
    final logo = L3bLogo.instance;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    if (white) {
      canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    }

    final swoosh = logo.swoosh.path.transform(
      Float64List.fromList([
        swooshShrink, 0, 0, 0, //
        0, 1, 0, 0, //
        0, 0, 1, 0, //
        swooshFrom * (1 - swooshShrink), 0, 0, 1,
      ]),
    );
    final markBounds = logo.ball
        .map((p) => p.bounds)
        .reduce((a, b) => a.expandToInclude(b))
        .expandToInclude(logo.five.bounds)
        .expandToInclude(swoosh.getBounds());
    final middle = markBounds.center;

    // The mark is [fraction] of the picture: of its width (the whole icon), or
    // of the circle round it (the part of the adaptive icon that is never cut).
    final double scale;
    if (byWidth) {
      scale = size * fraction / markBounds.width;
    } else {
      final far = [
        (middle - L3bLogo.ballCenter).distance + L3bLogo.ballRadius,
        (markBounds.topRight - middle).distance,
        (markBounds.bottomRight - middle).distance,
      ].reduce((a, b) => a > b ? a : b);
      scale = size * fraction / (2 * far);
    }
    canvas.translate(size / 2, size / 2);
    canvas.scale(scale);
    canvas.translate(-middle.dx, -middle.dy);

    final paint = ui.Paint()..isAntiAlias = true;
    for (final piece in logo.ball) {
      canvas.drawPath(piece.path, paint..color = piece.color);
    }
    canvas.drawPath(logo.five.path, paint..color = logo.five.color);
    canvas.drawPath(swoosh, paint..color = logo.swoosh.color);

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  test('renders the icon pictures', () async {
    Directory(dir!).createSync(recursive: true);
    await render(
      'app_icon_full.png',
      white: true,
      fraction: 0.78,
      byWidth: true,
    );
    await render(
      'app_icon_foreground.png',
      white: false,
      fraction: 0.77,
      byWidth: false,
    );
  }, skip: dir == null);
}
