import 'dart:math' as math;
import 'dart:ui';

/// The word "SIUUU" that pops out when the player shouts it. The letters are
/// drawn here, with a thick pen, so that they are the same on every phone (a
/// font is not): each one is a line, and is to be stroked with a pen
/// [stroke] wide with flat ends.
abstract final class SiuText {
  static const String word = 'SIUUU';

  /// How thick the pen is, how high a letter is, and the space between them
  /// (units of the scene).
  static const double stroke = 5.2;
  static const double height = 25;
  static const double gap = 3.2;

  /// How wide an S or a U is.
  static const double wide = 17.5;

  /// How much the letters lean: the top is this much of the height to the
  /// right, like the letters of the logo.
  static const double slant = 0.24;

  /// The Us grow, as the shout goes on (a part of [height] for each letter).
  static const List<double> growth = [1, 1, 1, 1.1, 1.24];

  static double widthOf(String letter) => letter == 'I' ? stroke : wide;

  /// The width of the whole word.
  static double get width {
    var w = gap * (word.length - 1);
    for (var i = 0; i < word.length; i++) {
      w += widthOf(word[i]);
    }
    return w;
  }

  /// The line of [letter] ("S", "I" or "U"), [high] units high, standing on
  /// y = 0 with its left side at x = 0.
  static Path letter(String letter, double high) {
    final w = widthOf(letter);
    final path = Path();
    switch (letter) {
      case 'I':
        path
          ..moveTo(w / 2, -high)
          ..lineTo(w / 2, 0);
      case 'U':
        final left = stroke / 2;
        final right = w - stroke / 2;
        final r = (right - left) / 2;
        final centerY = -stroke / 2 - r;
        path
          ..moveTo(left, -high)
          ..lineTo(left, centerY)
          // Round the bottom, from the left to the right.
          ..arcTo(
            Rect.fromCircle(center: Offset(w / 2, centerY), radius: r),
            math.pi,
            -math.pi,
            false,
          )
          ..lineTo(right, -high);
      default: // S: two bowls, the top one open to the right.
        final top = -high + stroke / 2;
        final bottom = -stroke / 2;
        final ry = (bottom - top) / 4;
        final rx = (w - stroke) / 2;
        const open = 0.18 * math.pi;
        path
          ..arcTo(
            Rect.fromCenter(
              center: Offset(w / 2, top + ry),
              width: 2 * rx,
              height: 2 * ry,
            ),
            -open,
            -(1.5 * math.pi - open),
            true,
          )
          ..arcTo(
            Rect.fromCenter(
              center: Offset(w / 2, top + 3 * ry),
              width: 2 * rx,
              height: 2 * ry,
            ),
            -math.pi / 2,
            1.5 * math.pi - open,
            false,
          );
    }
    return path;
  }
}
