import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'logo_data.dart';

/// One animated piece of the logo, ready to be painted.
class LogoPiece {
  LogoPiece._(this.name, this.color, this.path) : bounds = path.getBounds();

  factory LogoPiece.from(LogoPartData data) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final c in data.contours) {
      path.moveTo(c[0], c[1]);
      for (var i = 2; i < c.length; i += 2) {
        path.lineTo(c[i], c[i + 1]);
      }
      path.close();
    }
    return LogoPiece._(data.name, Color(data.color), path);
  }

  final String name;
  final Color color;
  final Path path;
  final Rect bounds;

  Offset get center => bounds.center;
}

/// The 5L3B logo, cut into the pieces that move on their own: the ball (its
/// patches), the 5, the stroke that shoots out of its top bar, and the
/// letters L, 3 and B. All in the units of [size], with (0, 0) at the top
/// left of the logo.
///
/// There is one more piece, [ballFill], which is not in the logo: the piece
/// of the ball that the 5 covers. While the ball is on its own, it is filled.
class L3bLogo {
  L3bLogo._() {
    for (final data in kLogoParts) {
      final piece = LogoPiece.from(data);
      switch (data.name) {
        case 'ball_navy' || 'ball_blue':
          ball.add(piece);
        case 'ball_fill':
          ballFill = piece;
        case 'five':
          five = piece;
        case 'swoosh':
          swoosh = piece;
        default:
          letters.add(piece);
      }
    }
  }

  /// Built once: the paths are the same for every frame.
  static final L3bLogo instance = L3bLogo._();

  static const Size size = Size(kLogoWidth, kLogoHeight);
  static const Offset ballCenter = Offset(kBallCx, kBallCy);
  static const double ballRadius = kBallRadius;

  /// Where the ball touches the ground.
  static const double ballBottom = kBallCy + kBallRadius;

  final List<LogoPiece> ball = [];
  final List<LogoPiece> letters = [];
  late final LogoPiece ballFill;
  late final LogoPiece five;
  late final LogoPiece swoosh;

  /// What the logo is made of when it is at rest.
  List<LogoPiece> get all => [...ball, five, swoosh, ...letters];

  /// The height of the middle of the stroke at [x].
  double swooshMiddleAt(double x) {
    const m = kSwooshMiddle;
    if (x <= m[0]) return m[1];
    for (var i = 3; i < m.length; i += 3) {
      if (x <= m[i]) {
        final t = (x - m[i - 3]) / (m[i] - m[i - 3]);
        return lerpDouble(m[i - 2], m[i + 1], t)!;
      }
    }
    return m[m.length - 2];
  }

  /// Paints the logo as it rests, at the size of [Canvas]'s current units.
  void paintRest(Canvas canvas) {
    final paint = Paint();
    for (final piece in all) {
      canvas.drawPath(piece.path, paint..color = piece.color);
    }
  }
}

/// The logo at rest, fitted to the space it is given.
class L3bLogoView extends StatelessWidget {
  const L3bLogoView({super.key, this.width});

  /// Width of the logo; the space it is given when null.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final logo = Semantics(
      label: '5L3B',
      image: true,
      child: AspectRatio(
        aspectRatio: kLogoWidth / kLogoHeight,
        child: const CustomPaint(painter: _RestPainter()),
      ),
    );
    return width == null ? logo : SizedBox(width: width, child: logo);
  }
}

class _RestPainter extends CustomPainter {
  const _RestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / kLogoWidth);
    L3bLogo.instance.paintRest(canvas);
  }

  @override
  bool shouldRepaint(_RestPainter oldDelegate) => false;
}
