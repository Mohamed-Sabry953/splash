import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:l3b_splash/splash/l3b_logo.dart';
import 'package:l3b_splash/splash/player.dart';

/// Draws the poses of the player side by side into the folder
/// `L3B_FRAMES_DIR` (a development aid; does nothing without it).
void main() {
  final dir = Platform.environment['L3B_FRAMES_DIR'];

  test('renders the poses', () async {
    Directory(dir!).createSync(recursive: true);
    final poses = {
      'ready': PlayerPoses.ready,
      'backswing': PlayerPoses.backswing,
      'strike': PlayerPoses.strike,
      'follow': PlayerPoses.follow,
      'cheer': PlayerPoses.cheer,
    };
    const cell = 220.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(2);
    canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    var i = 0;
    for (final entry in poses.entries) {
      canvas.save();
      canvas.translate(cell * i + cell / 2, 130);
      final rig = PlayerRig(entry.value, ground: 96);
      canvas.drawLine(
        const ui.Offset(-100, 96),
        const ui.Offset(100, 96),
        ui.Paint()
          ..color = const ui.Color(0xFFCCD6E6)
          ..strokeWidth = 1.5,
      );
      rig.paint(canvas, number: L3bLogo.instance.five.path);
      canvas.restore();
      i++;
    }
    final image = await recorder.endRecording().toImage(
      (cell * poses.length * 2).round(),
      (260 * 2).round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/poses.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  }, skip: dir == null);
}
