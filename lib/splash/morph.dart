import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Something to turn into dust, or to make out of dust: a shape, the color it
/// is painted in, and a [role] that says which dust goes where (the green dust
/// of one shape goes to the green parts of the other).
class DustShape {
  DustShape(this.path, this.color, this.role) : bounds = path.getBounds();

  final Path path;
  final Color color;
  final int role;

  /// A quick way to say "no" before asking the path.
  final Rect bounds;

  bool contains(Offset p) => bounds.contains(p) && path.contains(p);
}

/// A cloud of small squares that flows from one shape into another: the
/// letters into the player and the player back into the letters.
///
/// Both ends are sampled with the same number of dots, so that every dot has
/// a place to go. Dots are matched left to right and top to bottom, so the
/// cloud moves as one body and does not mix up.
class DustMorph {
  DustMorph._({
    required this.count,
    required this.from,
    required this.to,
    required this.ctrl,
    required this.delay,
    required this.sizeFrom,
    required this.sizeTo,
    required this.colorFrom,
    required this.colorTo,
  });

  /// The dots of the shape [from] that has the natural number of dots, and the
  /// same number of dots across [to]. [step] is the distance between the dots
  /// of [from].
  factory DustMorph.between({
    required List<DustShape> from,
    required List<DustShape> to,
    required double step,
    required bool fromIsText,
    int roles = 2,
    int seed = 1,
  }) {
    final random = math.Random(seed);
    final src = <_Dot>[];
    final dst = <_Dot>[];
    // The text is sampled as it is; the player gets as many dots.
    final natural = fromIsText ? from : to;
    final counted = fromIsText ? to : from;
    for (var role = 0; role < roles; role++) {
      final a = _sample(natural, role, step: step, random: random);
      final area = _area(counted, role);
      if (area <= 0 || a.isEmpty) continue;
      final b = _sampleCount(counted, role, a.length, area, random);
      final ordered = _match(a, b);
      src.addAll(fromIsText ? ordered.$1 : ordered.$2);
      dst.addAll(fromIsText ? ordered.$2 : ordered.$1);
    }

    final n = src.length;
    final text = fromIsText ? src : dst;
    final x0 = text.map((d) => d.x).reduce(math.min);
    final x1 = text.map((d) => d.x).reduce(math.max);
    final fromList = Float32List(n * 2);
    final toList = Float32List(n * 2);
    final ctrl = Float32List(n * 2);
    final delay = Float32List(n);
    final sizeFrom = Float32List(n);
    final sizeTo = Float32List(n);
    final colorFrom = Int32List(n);
    final colorTo = Int32List(n);
    for (var i = 0; i < n; i++) {
      final s = src[i];
      final d = dst[i];
      fromList[i * 2] = s.x;
      fromList[i * 2 + 1] = s.y;
      toList[i * 2] = d.x;
      toList[i * 2 + 1] = d.y;
      // The path bends to one side or the other, and a little up.
      final dx = d.x - s.x;
      final dy = d.y - s.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      final bend =
          (random.nextDouble() * 0.5 + 0.1) * (random.nextBool() ? 1 : -1);
      ctrl[i * 2] = (s.x + d.x) / 2 - dy * bend;
      ctrl[i * 2 + 1] = (s.y + d.y) / 2 + dx * bend - dist * 0.18;
      // The left of the text goes first: the same for both ways.
      final lead = ((fromIsText ? s.x : d.x) - x0) / math.max(x1 - x0, 1);
      delay[i] = (lead * 0.78 + random.nextDouble() * 0.22).clamp(0.0, 1.0);
      sizeFrom[i] = s.size;
      sizeTo[i] = d.size;
      colorFrom[i] = s.color;
      colorTo[i] = d.color;
    }
    return DustMorph._(
      count: n,
      from: fromList,
      to: toList,
      ctrl: ctrl,
      delay: delay,
      sizeFrom: sizeFrom,
      sizeTo: sizeTo,
      colorFrom: colorFrom,
      colorTo: colorTo,
    );
  }

  final int count;
  final Float32List from;
  final Float32List to;
  final Float32List ctrl;
  final Float32List delay;
  final Float32List sizeFrom;
  final Float32List sizeTo;
  final Int32List colorFrom;
  final Int32List colorTo;

  /// How much of the time the first dot starts before the last one.
  static const double spread = 0.46;

  /// Paints the cloud when it has done [progress] (0..1) of its way.
  void paint(Canvas canvas, double progress, {double alpha = 1}) {
    if (alpha <= 0) return;
    final positions = Float32List(count * 12);
    final colors = Int32List(count * 6);
    final a = (alpha * 255).round().clamp(0, 255);
    for (var i = 0; i < count; i++) {
      final local = ((progress - delay[i] * spread) / (1 - spread)).clamp(
        0.0,
        1.0,
      );
      final e = _easeInOutCubic(local);
      final u = 1 - e;
      final x =
          u * u * from[i * 2] + 2 * u * e * ctrl[i * 2] + e * e * to[i * 2];
      final y =
          u * u * from[i * 2 + 1] +
          2 * u * e * ctrl[i * 2 + 1] +
          e * e * to[i * 2 + 1];
      final h = (sizeFrom[i] + (sizeTo[i] - sizeFrom[i]) * e) / 2;
      final o = i * 12;
      positions[o] = x - h;
      positions[o + 1] = y - h;
      positions[o + 2] = x + h;
      positions[o + 3] = y - h;
      positions[o + 4] = x - h;
      positions[o + 5] = y + h;
      positions[o + 6] = x + h;
      positions[o + 7] = y - h;
      positions[o + 8] = x + h;
      positions[o + 9] = y + h;
      positions[o + 10] = x - h;
      positions[o + 11] = y + h;
      final c = _mix(colorFrom[i], colorTo[i], e, a);
      for (var k = 0; k < 6; k++) {
        colors[i * 6 + k] = c;
      }
    }
    final vertices = Vertices.raw(
      VertexMode.triangles,
      positions,
      colors: colors,
    );
    canvas.drawVertices(vertices, BlendMode.dst, Paint());
    vertices.dispose();
  }

  static double _easeInOutCubic(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;

  /// Colors are 0xAARRGGBB; the alpha is the one given.
  static int _mix(int a, int b, double t, int alpha) {
    int ch(int shift) {
      final p = (a >> shift) & 0xFF;
      final q = (b >> shift) & 0xFF;
      return (p + (q - p) * t).round();
    }

    return (alpha << 24) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }

  // --- sampling -----------------------------------------------------------

  /// The dots that fill the shapes of [role], every [step] units.
  static List<_Dot> _sample(
    List<DustShape> shapes,
    int role, {
    required double step,
    required math.Random random,
  }) {
    final dots = <_Dot>[];
    final bounds = _bounds(shapes);
    for (var y = bounds.top + step / 2; y < bounds.bottom; y += step) {
      for (var x = bounds.left + step / 2; x < bounds.right; x += step) {
        final hit = _shapeAt(shapes, Offset(x, y));
        if (hit != null && hit.role == role) {
          dots.add(_Dot(x, y, step * 1.06, hit.color.toARGB32()));
        }
      }
    }
    return dots;
  }

  /// [count] dots that fill the shapes of [role]: sampled at the distance that
  /// gives about that many, then trimmed or topped up.
  static List<_Dot> _sampleCount(
    List<DustShape> shapes,
    int role,
    int count,
    double area,
    math.Random random,
  ) {
    final step = math.sqrt(area / count);
    final dots = <_Dot>[];
    final bounds = _bounds(shapes);
    for (var y = bounds.top + step / 2; y < bounds.bottom; y += step) {
      for (var x = bounds.left + step / 2; x < bounds.right; x += step) {
        // A little off the grid, so that the dots do not look like a grid.
        final jx = x + (random.nextDouble() - 0.5) * step * 0.4;
        final jy = y + (random.nextDouble() - 0.5) * step * 0.4;
        final hit = _shapeAt(shapes, Offset(jx, jy));
        if (hit != null && hit.role == role) {
          dots.add(_Dot(jx, jy, step * 1.12, hit.color.toARGB32()));
        }
      }
    }
    dots.shuffle(random);
    while (dots.length > count) {
      dots.removeLast();
    }
    var i = 0;
    while (dots.length < count && dots.isNotEmpty) {
      final d = dots[i++ % dots.length];
      dots.add(
        _Dot(
          d.x + (random.nextDouble() - 0.5) * step,
          d.y + (random.nextDouble() - 0.5) * step,
          d.size,
          d.color,
        ),
      );
    }
    return dots;
  }

  /// How much room the shapes of [role] take, in square units.
  static double _area(List<DustShape> shapes, int role) {
    const fine = 1.5;
    final bounds = _bounds(shapes);
    var cells = 0;
    for (var y = bounds.top + fine / 2; y < bounds.bottom; y += fine) {
      for (var x = bounds.left + fine / 2; x < bounds.right; x += fine) {
        final hit = _shapeAt(shapes, Offset(x, y));
        if (hit != null && hit.role == role) cells++;
      }
    }
    return cells * fine * fine;
  }

  static Rect _bounds(List<DustShape> shapes) {
    var r = shapes.first.path.getBounds();
    for (final s in shapes.skip(1)) {
      r = r.expandToInclude(s.path.getBounds());
    }
    return r;
  }

  /// The shape on top at [p], or null.
  static DustShape? _shapeAt(List<DustShape> shapes, Offset p) {
    for (var i = shapes.length - 1; i >= 0; i--) {
      if (shapes[i].contains(p)) return shapes[i];
    }
    return null;
  }

  /// Puts the dots of both ends in the same order: by columns from left to
  /// right, and from top to bottom in each column.
  static (List<_Dot>, List<_Dot>) _match(List<_Dot> a, List<_Dot> b) {
    return (_order(a), _order(b));
  }

  static List<_Dot> _order(List<_Dot> dots) {
    const columns = 12;
    final sorted = [...dots]..sort((p, q) => p.x.compareTo(q.x));
    final out = <_Dot>[];
    for (var c = 0; c < columns; c++) {
      final from = sorted.length * c ~/ columns;
      final to = sorted.length * (c + 1) ~/ columns;
      final column = sorted.sublist(from, to)
        ..sort((p, q) => p.y.compareTo(q.y));
      out.addAll(c.isOdd ? column.reversed : column);
    }
    return out;
  }
}

class _Dot {
  const _Dot(this.x, this.y, this.size, this.color);

  final double x;
  final double y;
  final double size;
  final int color;
}
