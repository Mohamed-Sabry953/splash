import 'dart:math' as math;
import 'dart:ui';

/// The footballer the letters turn into, seen from the side.
///
/// Every angle is in radians, measured from "straight down" and positive when
/// it swings to the front (the way the player faces). A leg or an arm hanging
/// down is 0; held out in front of the body, a quarter of a turn.
class PlayerPose {
  const PlayerPose({
    this.lean = 0,
    this.headTilt = 0,
    this.kickThigh = 0,
    this.kickKnee = 0,
    this.kickFoot = _quarter,
    this.plantThigh = 0,
    this.plantKnee = 0,
    this.plantFoot = _quarter,
    this.plantFlat = 1,
    this.nearArm = 0,
    this.nearElbow = 0,
    this.farArm = 0,
    this.farElbow = 0,
    this.roll = 0,
    this.lift = 0,
    this.x = 0,
  });

  static const double _quarter = math.pi / 2;

  /// The body leans forward by this much (backwards when negative).
  final double lean;
  final double headTilt;

  /// The leg that kicks, nearest to the viewer: the angle of the thigh, how
  /// much the knee is bent (the shin goes back by that), and the foot's angle
  /// from the shin.
  final double kickThigh;
  final double kickKnee;
  final double kickFoot;

  /// The other leg, farther from the viewer. When [plantFlat] is 1 its foot
  /// is flat on the ground, whatever the leg does; at 0 it is [plantFoot]
  /// from the shin, like the other one.
  final double plantThigh;
  final double plantKnee;
  final double plantFoot;
  final double plantFlat;

  /// An arm: the angle of its upper part, and how much the elbow bends to the
  /// front.
  final double nearArm;
  final double nearElbow;
  final double farArm;
  final double farElbow;

  /// The whole body turned backwards about the hip: a quarter of a turn
  /// leaves it lying on its back.
  final double roll;

  /// How high the hip is above where it is when the player stands (negative:
  /// lower).
  final double lift;

  /// Where the hip is, from where the player stands.
  final double x;

  PlayerPose copyWith({double? lift, double? x}) => PlayerPose(
    lean: lean,
    headTilt: headTilt,
    kickThigh: kickThigh,
    kickKnee: kickKnee,
    kickFoot: kickFoot,
    plantThigh: plantThigh,
    plantKnee: plantKnee,
    plantFoot: plantFoot,
    plantFlat: plantFlat,
    nearArm: nearArm,
    nearElbow: nearElbow,
    farArm: farArm,
    farElbow: farElbow,
    roll: roll,
    lift: lift ?? this.lift,
    x: x ?? this.x,
  );

  static PlayerPose lerp(PlayerPose a, PlayerPose b, double t) {
    double l(double p, double q) => p + (q - p) * t;
    return PlayerPose(
      lean: l(a.lean, b.lean),
      headTilt: l(a.headTilt, b.headTilt),
      kickThigh: l(a.kickThigh, b.kickThigh),
      kickKnee: l(a.kickKnee, b.kickKnee),
      kickFoot: l(a.kickFoot, b.kickFoot),
      plantThigh: l(a.plantThigh, b.plantThigh),
      plantKnee: l(a.plantKnee, b.plantKnee),
      plantFoot: l(a.plantFoot, b.plantFoot),
      plantFlat: l(a.plantFlat, b.plantFlat),
      nearArm: l(a.nearArm, b.nearArm),
      nearElbow: l(a.nearElbow, b.nearElbow),
      farArm: l(a.farArm, b.farArm),
      farElbow: l(a.farElbow, b.farElbow),
      roll: l(a.roll, b.roll),
      lift: l(a.lift, b.lift),
      x: l(a.x, b.x),
    );
  }
}

double _rad(double degrees) => degrees * math.pi / 180;

/// The poses of the story, in the order they come. The player has his back to
/// where the ball goes: he looks up at the ball, jumps, falls backwards and
/// kicks it over his head (a bicycle kick), then lands on his back and jumps
/// up cheering.
abstract final class PlayerPoses {
  /// Just formed: looking up at the ball, the weight on one leg.
  static final PlayerPose ready = PlayerPose(
    lean: _rad(3),
    headTilt: _rad(-24),
    kickThigh: _rad(-10),
    kickKnee: _rad(16),
    kickFoot: _rad(86),
    plantThigh: _rad(6),
    plantKnee: _rad(8),
    nearArm: _rad(-18),
    nearElbow: _rad(14),
    farArm: _rad(24),
    farElbow: _rad(26),
  );

  /// Down, ready to jump: knees bent, the arms back.
  static final PlayerPose crouch = PlayerPose(
    lean: _rad(26),
    headTilt: _rad(-34),
    kickThigh: _rad(42),
    kickKnee: _rad(78),
    kickFoot: _rad(70),
    plantThigh: _rad(40),
    plantKnee: _rad(78),
    nearArm: _rad(-62),
    nearElbow: _rad(14),
    farArm: _rad(-48),
    farElbow: _rad(20),
  );

  /// Off the ground, stretched, the arms up.
  static final PlayerPose takeOff = PlayerPose(
    lean: _rad(-6),
    headTilt: _rad(-30),
    kickThigh: _rad(8),
    kickKnee: _rad(6),
    kickFoot: _rad(30),
    plantThigh: _rad(-2),
    plantKnee: _rad(4),
    plantFoot: _rad(30),
    plantFlat: 0,
    nearArm: _rad(150),
    nearElbow: _rad(8),
    farArm: _rad(132),
    farElbow: _rad(10),
    roll: _rad(18),
    lift: 34,
    x: 6,
  );

  /// Going over backwards: the far leg swings up, the other one waits.
  static final PlayerPose scissors = PlayerPose(
    lean: _rad(-8),
    headTilt: _rad(-24),
    kickThigh: _rad(-34),
    kickKnee: _rad(62),
    kickFoot: _rad(40),
    plantThigh: _rad(96),
    plantKnee: _rad(8),
    plantFoot: _rad(36),
    plantFlat: 0,
    nearArm: _rad(-110),
    nearElbow: _rad(12),
    farArm: _rad(95),
    farElbow: _rad(24),
    roll: _rad(58),
    lift: 62,
    x: 16,
  );

  /// The kick: the body is flat in the air, the kicking leg is straight up,
  /// the other one has come down.
  static final PlayerPose strike = PlayerPose(
    lean: _rad(-4),
    headTilt: _rad(-14),
    kickThigh: _rad(104),
    kickKnee: _rad(6),
    kickFoot: _rad(54),
    plantThigh: _rad(-36),
    plantKnee: _rad(30),
    plantFoot: _rad(40),
    plantFlat: 0,
    nearArm: _rad(-96),
    nearElbow: _rad(10),
    farArm: _rad(70),
    farElbow: _rad(20),
    roll: _rad(84),
    lift: 78,
    x: 26,
  );

  /// Falling on his back, the legs going on over.
  static final PlayerPose fall = PlayerPose(
    lean: _rad(-4),
    headTilt: _rad(-18),
    kickThigh: _rad(146),
    kickKnee: _rad(38),
    kickFoot: _rad(40),
    plantThigh: _rad(-24),
    plantKnee: _rad(20),
    plantFoot: _rad(40),
    plantFlat: 0,
    nearArm: _rad(-120),
    nearElbow: _rad(8),
    farArm: _rad(-70),
    farElbow: _rad(16),
    roll: _rad(96),
    lift: 40,
    x: 34,
  );

  /// On the ground, on his back.
  static final PlayerPose lying = PlayerPose(
    lean: _rad(-2),
    headTilt: _rad(-6),
    kickThigh: _rad(120),
    kickKnee: _rad(50),
    kickFoot: _rad(50),
    plantThigh: _rad(-10),
    plantKnee: _rad(8),
    plantFoot: _rad(60),
    plantFlat: 0,
    nearArm: _rad(-14),
    nearElbow: _rad(10),
    farArm: _rad(46),
    farElbow: _rad(12),
    roll: _rad(92),
    lift: -62,
    x: 38,
  );

  /// Both arms up, cheering.
  static final PlayerPose cheer = PlayerPose(
    lean: _rad(-4),
    headTilt: _rad(-12),
    kickThigh: _rad(-10),
    kickKnee: _rad(20),
    kickFoot: _rad(86),
    plantThigh: _rad(10),
    plantKnee: _rad(12),
    nearArm: _rad(158),
    nearElbow: _rad(6),
    farArm: _rad(138),
    farElbow: _rad(12),
    x: 14,
  );
}

/// The shape of a body part, and what it is made of.
class BodyPart {
  const BodyPart(this.path, this.role);

  final Path path;

  /// Which color it takes (see [PlayerRig.colors]).
  final BodyRole role;
}

enum BodyRole {
  skin,
  farSkin,
  shirt,
  farShirt,
  shorts,
  farShorts,
  sock,
  farSock,
  boot,
  farBoot,
  hair,
}

/// Where the parts of the body are for a pose, and the shapes to paint.
///
/// The player is built in his own space (x to the front, y down, the hip at
/// 0, 0), then turned about the hip by the roll, flipped when he faces left,
/// and put where he is.
class PlayerRig {
  PlayerRig(this.pose, {required this.ground, this.facing = 1}) {
    _build();
  }

  /// How the body is measured, in the units of the scene.
  static const double thigh = 38;
  static const double shin = 37;
  static const double foot = 14;
  static const double torso = 50;
  static const double headRadius = 11.5;
  static const double upperArm = 24;
  static const double foreArm = 23;
  static const double ankleHeight = 5;

  final PlayerPose pose;

  /// The height of the ground in the scene.
  final double ground;

  /// 1 when he faces right, -1 when he faces left.
  final double facing;

  late final Offset hip;
  late final Offset shoulder;
  late final Offset head;
  late final Offset kickKnee, kickAnkle, kickToe;
  late final Offset plantKnee, plantAnkle, plantToe;
  late final Offset nearElbow, nearHand, farElbow, farHand;

  /// All the parts, from the back to the front.
  late final List<BodyPart> parts;

  /// The parts of the leg that kicks, for the trail behind it.
  late final List<Path> kickingLeg;

  static Offset _dir(double angle) => Offset(math.sin(angle), math.cos(angle));

  late final Offset _origin;
  late final double _cos, _sin;

  /// A point of the player's own space, where it is on the scene.
  Offset _w(Offset p) {
    final r = Offset(_cos * p.dx - _sin * p.dy, _sin * p.dx + _cos * p.dy);
    return _origin + Offset(r.dx * facing, r.dy);
  }

  void _build() {
    final p = pose;
    final theta = -p.roll;
    _cos = math.cos(theta);
    _sin = math.sin(theta);

    // The player stands on the far leg: that decides how high the hip is.
    final plantShin = p.plantThigh - p.plantKnee;
    final legHeight =
        thigh * math.cos(p.plantThigh) + shin * math.cos(plantShin);
    _origin = Offset(p.x, ground - ankleHeight - legHeight - p.lift);

    final up = Offset(math.sin(p.lean), -math.cos(p.lean));
    final headUp = Offset(
      math.sin(p.lean + p.headTilt),
      -math.cos(p.lean + p.headTilt),
    );
    final shoulderL = up * (torso - 5);
    final headL = up * torso + headUp * (headRadius + 5);

    final plantKneeL = _dir(p.plantThigh) * thigh;
    final plantAnkleL = plantKneeL + _dir(plantShin) * shin;
    final plantFootAngle = _lerpAngle(
      plantShin + p.plantFoot,
      math.pi / 2,
      p.plantFlat,
    );
    final plantToeL = plantAnkleL + _dir(plantFootAngle) * foot;

    final kickShin = p.kickThigh - p.kickKnee;
    final kickKneeL = _dir(p.kickThigh) * thigh;
    final kickAnkleL = kickKneeL + _dir(kickShin) * shin;
    final kickToeL = kickAnkleL + _dir(kickShin + p.kickFoot) * foot;

    final nearElbowL = shoulderL + _dir(p.nearArm) * upperArm;
    final nearHandL = nearElbowL + _dir(p.nearArm + p.nearElbow) * foreArm;
    final farElbowL = shoulderL + _dir(p.farArm) * upperArm;
    final farHandL = farElbowL + _dir(p.farArm + p.farElbow) * foreArm;

    hip = _w(Offset.zero);
    shoulder = _w(shoulderL);
    head = _w(headL);
    kickKnee = _w(kickKneeL);
    kickAnkle = _w(kickAnkleL);
    kickToe = _w(kickToeL);
    plantKnee = _w(plantKneeL);
    plantAnkle = _w(plantAnkleL);
    plantToe = _w(plantToeL);
    nearElbow = _w(nearElbowL);
    nearHand = _w(nearHandL);
    farElbow = _w(farElbowL);
    farHand = _w(farHandL);

    final farLeg = _leg(
      kneeL: plantKneeL,
      ankleL: plantAnkleL,
      toeL: plantToeL,
      skin: BodyRole.farSkin,
      shorts: BodyRole.farShorts,
      sock: BodyRole.farSock,
      boot: BodyRole.farBoot,
    );
    final nearLeg = _leg(
      kneeL: kickKneeL,
      ankleL: kickAnkleL,
      toeL: kickToeL,
      skin: BodyRole.skin,
      shorts: BodyRole.shorts,
      sock: BodyRole.sock,
      boot: BodyRole.boot,
    );

    const sleeve = 0.55;
    parts = [
      // The arm that is far.
      ..._arm(
        shoulderL,
        farElbowL,
        farHandL,
        BodyRole.farSkin,
        BodyRole.farShirt,
        sleeve,
      ),
      ...farLeg,
      // The neck and the body.
      BodyPart(
        _capsule(_w(up * (torso - 9)), 4.8, head, 4.6),
        BodyRole.farSkin,
      ),
      BodyPart(_capsule(hip, 10.6, _w(up * 4), 10.6), BodyRole.shorts),
      BodyPart(_capsule(hip, 10.8, shoulder, 13.4), BodyRole.shirt),
      ..._head(headL, headUp),
      // The leg and the arm that are near.
      ...nearLeg,
      ..._arm(
        shoulderL,
        nearElbowL,
        nearHandL,
        BodyRole.skin,
        BodyRole.shirt,
        sleeve,
      ),
    ];
    kickingLeg = [
      for (final part in nearLeg)
        if (part.role != BodyRole.shorts) part.path,
    ];
  }

  static double _lerpAngle(double a, double b, double t) => a + (b - a) * t;

  /// A leg: the shorts over the top of the thigh, the skin of the knee, the
  /// sock over the lower shin, and the boot.
  List<BodyPart> _leg({
    required Offset kneeL,
    required Offset ankleL,
    required Offset toeL,
    required BodyRole skin,
    required BodyRole shorts,
    required BodyRole sock,
    required BodyRole boot,
  }) {
    final knee = _w(kneeL);
    final ankle = _w(ankleL);
    final midShin = Offset.lerp(knee, ankle, 0.46)!;
    final endShorts = Offset.lerp(hip, knee, 0.46)!;
    return [
      BodyPart(_capsule(hip, 9.2, knee, 6.6), skin),
      BodyPart(_capsule(knee, 6.6, ankle, 4.2), skin),
      BodyPart(_capsule(midShin, 5.8, ankle, 4.5), sock),
      BodyPart(_capsule(hip, 9.6, endShorts, 8.6), shorts),
      BodyPart(_boot(ankleL, toeL), boot),
    ];
  }

  /// A boot: a heel, a sole and a toe, drawn from the ankle to the toe.
  Path _boot(Offset ankleL, Offset toeL) {
    final f = toeL - ankleL;
    final length = f.distance;
    final u = f / length; // along the foot
    final v = Offset(-u.dy, u.dx); // towards the sole
    Offset at(double along, double across) =>
        _w(ankleL + u * along + v * across);
    final points = [
      at(-4.4, -4.6),
      at(-5.2, 3.2),
      at(-1.5, 5.2),
      at(length - 2.5, 5.2),
      at(length + 2.2, 3.0),
      at(length + 2.8, 0.2),
      at(length - 2.0, -3.6),
      at(3.5, -4.8),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  /// An arm: skin, with the sleeve of the shirt over the top of it, and a hand.
  List<BodyPart> _arm(
    Offset shoulderL,
    Offset elbowL,
    Offset handL,
    BodyRole skin,
    BodyRole shirt,
    double sleeve,
  ) {
    final s = _w(shoulderL);
    final e = _w(elbowL);
    final h = _w(handL);
    return [
      BodyPart(_capsule(s, 5.4, e, 4.6), skin),
      BodyPart(_capsule(e, 4.6, h, 3.6), skin),
      BodyPart(_capsule(h, 4.6, h, 4.6), skin),
      BodyPart(_capsule(s, 6.6, Offset.lerp(s, e, sleeve)!, 5.8), shirt),
    ];
  }

  /// The head: skin, an ear, and hair over the top and the back.
  List<BodyPart> _head(Offset headL, Offset up) {
    // In the head's own frame the face looks to the front (x) and up is [up].
    final front = Offset(-up.dy, up.dx);
    Offset onHead(double angle, double radius) {
      final d = front * math.cos(angle) + up * math.sin(angle);
      return _w(headL + d * radius);
    }

    final c = _w(headL);
    final hair = Path()..moveTo(c.dx, c.dy);
    const from = 0.52; // above the forehead
    const to = 3.75; // down the back of the neck
    const steps = 12;
    for (var i = 0; i <= steps; i++) {
      final a = from + (to - from) * i / steps;
      final p = onHead(a, headRadius + 0.7);
      hair.lineTo(p.dx, p.dy);
    }
    hair.close();
    final ear = onHead(3.0, headRadius * 0.15);
    final eye = onHead(0.28, headRadius * 0.56);
    return [
      BodyPart(_capsule(c, headRadius, c, headRadius), BodyRole.skin),
      BodyPart(_capsule(ear, 2.4, ear, 2.4), BodyRole.farSkin),
      BodyPart(hair, BodyRole.hair),
      BodyPart(_capsule(eye, 1.25, eye, 1.25), BodyRole.hair),
    ];
  }

  /// A rounded bar from [a] to [b], [ra] wide at one end and [rb] at the other.
  static Path _capsule(Offset a, double ra, Offset b, double rb) {
    final path = Path()
      ..addOval(Rect.fromCircle(center: a, radius: ra))
      ..addOval(Rect.fromCircle(center: b, radius: rb));
    final d = b - a;
    final length = d.distance;
    if (length > 0.001) {
      final n = Offset(-d.dy, d.dx) / length;
      path
        // Round the same way as the circles, or they would cancel each other
        // where they overlap.
        ..moveTo(a.dx - n.dx * ra, a.dy - n.dy * ra)
        ..lineTo(b.dx - n.dx * rb, b.dy - n.dy * rb)
        ..lineTo(b.dx + n.dx * rb, b.dy + n.dy * rb)
        ..lineTo(a.dx + n.dx * ra, a.dy + n.dy * ra)
        ..close();
    }
    return path;
  }

  /// The colors of the parts.
  static const Map<BodyRole, Color> colors = {
    BodyRole.skin: Color(0xFFE2A97F),
    BodyRole.farSkin: Color(0xFFC48660),
    BodyRole.shirt: Color(0xFF8DC641),
    BodyRole.farShirt: Color(0xFF6FA52E),
    BodyRole.shorts: Color(0xFF0A2B60),
    BodyRole.farShorts: Color(0xFF163F7E),
    BodyRole.sock: Color(0xFF8DC641),
    BodyRole.farSock: Color(0xFF6FA52E),
    BodyRole.boot: Color(0xFF0A2B60),
    BodyRole.farBoot: Color(0xFF163F7E),
    BodyRole.hair: Color(0xFF0A2B60),
  };

  /// Whether a role is painted with the green of the shirt.
  static bool isGreen(BodyRole role) =>
      role == BodyRole.shirt ||
      role == BodyRole.farShirt ||
      role == BodyRole.sock ||
      role == BodyRole.farSock;

  /// The part of the body at [point]; the one in front when there are
  /// several, and null when there is none.
  BodyPart? partAt(Offset point) {
    for (var i = parts.length - 1; i >= 0; i--) {
      if (parts[i].path.contains(point)) return parts[i];
    }
    return null;
  }

  /// Paints the player. [alpha] fades all of it together; [number] is
  /// painted on the shirt.
  void paint(Canvas canvas, {double alpha = 1, Path? number}) {
    if (alpha <= 0) return;
    // The parts overlap: they are painted solid, and faded all together.
    if (alpha < 1) {
      canvas.saveLayer(
        Rect.fromCenter(center: hip, width: 460, height: 460),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
    }
    final paint = Paint();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    for (final part in parts) {
      final color = colors[part.role]!;
      canvas.drawPath(part.path, paint..color = color);
      // The boots and the hair have corners: they are rounded by an outline.
      if (part.role == BodyRole.boot ||
          part.role == BodyRole.farBoot ||
          part.role == BodyRole.hair) {
        canvas.drawPath(part.path, stroke..color = color);
      }
    }
    if (number != null) _paintNumber(canvas, number);
    if (alpha < 1) canvas.restore();
  }

  /// The number on the shirt, white, small and turned with the body.
  void _paintNumber(Canvas canvas, Path number) {
    final bounds = number.getBounds();
    const height = 15.0;
    final middle = Offset.lerp(hip, shoulder, 0.5)!;
    final axis = shoulder - hip;
    canvas.save();
    canvas.translate(middle.dx, middle.dy);
    canvas.rotate(math.atan2(axis.dy, axis.dx) + math.pi / 2);
    canvas.scale(height / bounds.height);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    canvas.drawPath(number, Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  /// The leg that kicks, to paint a few faint copies of it as it swings.
  void paintKickingLeg(Canvas canvas, double alpha) {
    final paint = Paint()
      ..color = colors[BodyRole.shorts]!.withValues(alpha: alpha);
    for (final path in kickingLeg) {
      canvas.drawPath(path, paint);
    }
  }
}
