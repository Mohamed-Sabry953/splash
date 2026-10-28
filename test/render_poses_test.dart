import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:l3b_splash/splash/l3b_logo.dart';
import 'package:l3b_splash/splash/player.dart';

/// Draws the poses of the player side by side into the folder
/// `L3B_FRAMES_DIR` (a development aid; does nothing without it). `L3B_POSES`
/// (names, comma separated) picks some of them, and `L3B_SCALE` is how large.
void main() {
  final dir = Platform.environment['L3B_FRAMES_DIR'];
  final only = Platform.environment['L3B_POSES']?.split(',');
  final scale = double.tryParse(Platform.environment['L3B_SCALE'] ?? '') ?? 2;

  test('renders the poses', () async {
    Directory(dir!).createSync(recursive: true);
    final all = {
      'ready': PlayerPoses.ready,
      'crouch': PlayerPoses.crouch,
      'strike': PlayerPoses.strike,
      'lying': PlayerPoses.lying,
      'siuAir': PlayerPoses.siuAir,
      'siu': PlayerPoses.siu,
    };
    final poses = {
      for (final entry in all.entries)
        if (only == null || only.contains(entry.key)) entry.key: entry.value,
    };
    final columns = poses.length < 3 ? poses.length : 3;
    const cellWidth = 230.0;
    const cellHeight = 250.0;
    final rows = (poses.length + columns - 1) ~/ columns;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(scale);
    canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    var i = 0;
    for (final entry in poses.entries) {
      canvas.save();
      canvas.translate(
        cellWidth * (i % columns) + cellWidth / 2,
        cellHeight * (i ~/ columns) + 150,
      );
      final rig = PlayerRig(entry.value.copyWith(x: 0), ground: 56, facing: -1);
      canvas.drawLine(
        const ui.Offset(-100, 56),
        const ui.Offset(100, 56),
        ui.Paint()
          ..color = const ui.Color(0xFFCCD6E6)
          ..strokeWidth = 1.5,
      );
      rig.paint(canvas, number: L3bLogo.instance.five.path);
      canvas.restore();
      i++;
    }
    final image = await recorder.endRecording().toImage(
      (cellWidth * columns * scale).round(),
      (cellHeight * rows * scale).round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/poses.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  }, skip: dir == null);
}
