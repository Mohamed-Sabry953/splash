import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:l3b_splash/splash/splash_painter.dart';

/// Writes the splash as PNG pictures, one for each of the moments in
/// `L3B_FRAMES` (milliseconds, comma separated), into the folder
/// `L3B_FRAMES_DIR`. It does nothing unless both are set:
///
///   L3B_FRAMES_DIR=/tmp/frames L3B_FRAMES=0,600,1200 flutter test test/render_frames_test.dart
void main() {
  final dir = Platform.environment['L3B_FRAMES_DIR'];
  final frames = Platform.environment['L3B_FRAMES'];
  final width = double.tryParse(Platform.environment['L3B_WIDTH'] ?? '') ?? 390;
  final height =
      double.tryParse(Platform.environment['L3B_HEIGHT'] ?? '') ?? 844;

  test('renders the frames', () async {
    Directory(dir!).createSync(recursive: true);
    for (final ms in frames!.split(',').map(double.parse)) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.scale(2);
      canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
      SplashPainter(ms: ms).paint(canvas, ui.Size(width, height));
      final image = await recorder.endRecording().toImage(
        (width * 2).round(),
        (height * 2).round(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '$dir/f${ms.round().toString().padLeft(5, '0')}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  }, skip: dir == null || frames == null);
}
