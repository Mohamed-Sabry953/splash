import 'dart:math' as math;
import 'dart:ui';

/// The footballer the letters turn into: a figure made of thick limbs, seen
/// from the side, facing right (the way the goal is).
///
/// Every angle is in radians, measured from "straight down" and positive when
/// it swings to the front. A foot, a shin or an arm hanging down is 0; a leg
/// held out in front of the player is a quarter of a turn.
class PlayerPose {
  const PlayerPose({
    this.lean = 0,
    this.headTilt = 0,
    this.kickThigh = 0,
    this.kickKnee = 0,
    this.kickFoot = _quarter,
    this.plantThigh = 0,
    this.plantKnee = 0,
    this.nearArm = 0,
    this.nearElbow = 0,
    this.farArm = 0,
    this.farElbow = 0,
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

  /// The leg the player stands on, which is farther from the viewer. Its foot
  /// is flat on the ground.
  final double plantThigh;
  final double plantKnee;

  /// An arm: the angle of its upper part, and how much the elbow bends to the
  /// front.
  final double nearArm;
  final double nearElbow;
  final double farArm;
  final double farElbow;

  /// How high the player is above the ground: a jump.
  final double lift;

  /// Where the hip is, to the right of where the player stands.
  final double x;

  PlayerPose copyWith({double? lift, double? x}) => PlayerPose(
    lean: lean,
    headTilt: headTilt,
    kickThigh: kickThigh,
    kickKnee: kickKnee,
    kickFoot: kickFoot,
    plantThigh: plantThigh,
    plantKnee: plantKnee,
    nearArm: nearArm,
    nearElbow: nearElbow,
    farArm: farArm,
    farElbow: farElbow,
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
      nearArm: l(a.nearArm, b.nearArm),
      nearElbow: l(a.nearElbow, b.nearElbow),
      farArm: l(a.farArm, b.farArm),
      farElbow: l(a.farElbow, b.farElbow),
      lift: l(a.lift, b.lift),
      x: l(a.x, b.x),
    );
  }
}

double _rad(double degrees) => degrees * math.pi / 180;

/// The poses of the story, in the order they come.
abstract final class PlayerPoses {
  /// The player has just been formed: weight on the left leg, the kicking
  /// leg pulled back, the arms ready.
  static final PlayerPose ready = PlayerPose(
    lean: _rad(7),
    kickThigh: _rad(-26),
    kickKnee: _rad(50),
    kickFoot: _rad(80),
    plantThigh: _rad(7),
    plantKnee: _rad(14),
    nearArm: _rad(-38),
    nearElbow: _rad(24),
    farArm: _rad(48),
    farElbow: _rad(52),
  );

  /// The leg is cocked as far back as it goes.
  static final PlayerPose backswing = PlayerPose(
    lean: _rad(-3),
    kickThigh: _rad(-44),
    kickKnee: _rad(84),
    kickFoot: _rad(60),
    plantThigh: _rad(3),
    plantKnee: _rad(24),
    nearArm: _rad(-58),
    nearElbow: _rad(22),
    farArm: _rad(74),
    farElbow: _rad(60),
  );

  /// The foot meets the ball: the body leans back and the leg is out in front.
  static final PlayerPose strike = PlayerPose(
    lean: _rad(-16),
    kickThigh: _rad(66),
    kickKnee: _rad(14),
    kickFoot: _rad(38),
    plantThigh: _rad(-6),
    plantKnee: _rad(20),
    nearArm: _rad(-34),
    nearElbow: _rad(10),
    farArm: _rad(70),
    farElbow: _rad(46),
    x: -3,
  );

  /// After the kick the leg goes on, high, and the player is off the ground.
  static final PlayerPose follow = PlayerPose(
    lean: _rad(-24),
    kickThigh: _rad(98),
    kickKnee: _rad(26),
    kickFoot: _rad(34),
    plantThigh: _rad(-10),
    plantKnee: _rad(12),
    nearArm: _rad(-70),
    nearElbow: _rad(14),
    farArm: _rad(96),
    farElbow: _rad(34),
    lift: 8,
    x: -1,
  );

  /// Both arms up: the goal.
  static final PlayerPose cheer = PlayerPose(
    lean: _rad(-6),
    headTilt: _rad(-6),
    kickThigh: _rad(-12),
    kickKnee: _rad(24),
    kickFoot: _rad(86),
    plantThigh: _rad(10),
    plantKnee: _rad(14),
    nearArm: _rad(152),
    nearElbow: _rad(8),
    farArm: _rad(132),
    farElbow: _rad(14),
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
  /// The shirt and its sleeves.
  shirt,

  /// The shirt on the arm farther away.
  farShirt,

  /// The head, the shorts and the leg nearer to the viewer.
  dark,

  /// The leg farther from the viewer.
  farLeg,

  /// The boots.
  boot,
}

/// Where the parts of the body are for a pose, and the shapes to paint.
class PlayerRig {
  PlayerRig(this.pose, {required this.ground}) {
    _build();
  }

  /// How the body is measured, in the units of the scene.
  static const double thigh = 38;
  static const double shin = 37;
  static const double foot = 14;
  static const double torso = 50;
  static const double headRadius = 12.5;
  static const double upperArm = 24;
  static const double foreArm = 23;
  static const double ankleHeight = 5;

  final PlayerPose pose;

  /// The height of the ground in the scene.
  final double ground;

  late final Offset hip;
  late final Offset shoulder;
  late final Offset head;
  late final Offset kickKnee, kickAnkle, kickToe;
  late final Offset plantKnee, plantAnkle, plantToe;
  late final Offset nearElbow, nearHand, farElbow, farHand;

  /// All the parts, from the back to the front.
  late final List<BodyPart> parts;

  static Offset _dir(double angle) => Offset(math.sin(angle), math.cos(angle));

  void _build() {
    final p = pose;
    // The player stands on the planted leg: that decides how high the hip is.
    final plantShin = p.plantThigh - p.plantKnee;
    final legHeight =
        thigh * math.cos(p.plantThigh) + shin * math.cos(plantShin);
    hip = Offset(p.x, ground - p.lift - ankleHeight - legHeight);

    final up = Offset(math.sin(p.lean), -math.cos(p.lean));
    shoulder = hip + up * (torso - 4);
    final neck = Offset(
      math.sin(p.lean + p.headTilt),
      -math.cos(p.lean + p.headTilt),
    );
    head = hip + up * torso + neck * (headRadius + 3);

    plantKnee = hip + _dir(p.plantThigh) * thigh;
    plantAnkle = plantKnee + _dir(plantShin) * shin;
    plantToe = plantAnkle + _dir(math.pi / 2) * foot;

    final kickShin = p.kickThigh - p.kickKnee;
    kickKnee = hip + _dir(p.kickThigh) * thigh;
    kickAnkle = kickKnee + _dir(kickShin) * shin;
    kickToe = kickAnkle + _dir(kickShin + p.kickFoot) * foot;

    nearElbow = shoulder + _dir(p.nearArm) * upperArm;
    nearHand = nearElbow + _dir(p.nearArm + p.nearElbow) * foreArm;
    farElbow = shoulder + _dir(p.farArm) * upperArm;
    farHand = farElbow + _dir(p.farArm + p.farElbow) * foreArm;

    parts = [
      // The arm and the leg that are farther away.
      ..._limb(
        [shoulder, farElbow, farHand],
        [5.4, 4.6, 3.9],
        BodyRole.farShirt,
      ),
      ..._limb([hip, plantKnee, plantAnkle], [9, 7, 5.2], BodyRole.farLeg),
      BodyPart(_capsule(plantAnkle, 5, plantToe, 4.4), BodyRole.boot),
      // The body.
      BodyPart(_capsule(hip, 11.5, hip + up * 6, 11.5), BodyRole.dark),
      BodyPart(_capsule(hip, 11, shoulder, 14), BodyRole.shirt),
      BodyPart(_capsule(head, headRadius, head, headRadius), BodyRole.dark),
      // The leg and the arm that are nearer.
      ..._limb([hip, kickKnee, kickAnkle], [9.4, 7.4, 5.4], BodyRole.dark),
      BodyPart(_capsule(kickAnkle, 5.2, kickToe, 4.6), BodyRole.boot),
      ..._limb(
        [shoulder, nearElbow, nearHand],
        [5.8, 4.9, 4.2],
        BodyRole.shirt,
      ),
    ];
  }

  /// A chain of tapered capsules through [points], with a radius at each.
  static List<BodyPart> _limb(
    List<Offset> points,
    List<double> radii,
    BodyRole role,
  ) {
    return [
      for (var i = 0; i + 1 < points.length; i++)
        BodyPart(
          _capsule(points[i], radii[i], points[i + 1], radii[i + 1]),
          role,
        ),
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
    BodyRole.shirt: Color(0xFF8DC641),
    BodyRole.farShirt: Color(0xFF6FA52E),
    BodyRole.dark: Color(0xFF0A2B60),
    BodyRole.farLeg: Color(0xFF054FBA),
    BodyRole.boot: Color(0xFF0A2B60),
  };

  /// The part of the body at [point]; the one in front when there are
  /// several, and null when there is none.
  BodyPart? partAt(Offset point) {
    for (var i = parts.length - 1; i >= 0; i--) {
      if (parts[i].path.contains(point)) return parts[i];
    }
    return null;
  }

  /// Paints the player. [alpha] fades all of it together.
  void paint(Canvas canvas, {double alpha = 1, Path? number}) {
    if (alpha <= 0) return;
    // The parts overlap: they are painted solid, and faded all together.
    if (alpha < 1) {
      canvas.saveLayer(
        Rect.fromCenter(center: hip, width: 400, height: 400),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
    }
    final paint = Paint();
    for (final part in parts) {
      canvas.drawPath(part.path, paint..color = colors[part.role]!);
    }
    if (number != null) _paintNumber(canvas, number);
    if (alpha < 1) canvas.restore();
  }

  /// The number on the shirt, white, small and leaning with the body.
  void _paintNumber(Canvas canvas, Path number) {
    final bounds = number.getBounds();
    const height = 16.0;
    final middle = Offset.lerp(hip, shoulder, 0.48)!;
    canvas.save();
    canvas.translate(middle.dx, middle.dy);
    canvas.rotate(pose.lean);
    canvas.scale(height / bounds.height);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    canvas.drawPath(number, Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  /// The legs only, to paint a few faint copies of the kick.
  void paintKickingLeg(Canvas canvas, double alpha) {
    final paint = Paint()
      ..color = colors[BodyRole.dark]!.withValues(alpha: alpha);
    canvas.drawPath(_capsule(hip, 9.4, kickKnee, 7.4), paint);
    canvas.drawPath(_capsule(kickKnee, 7.4, kickAnkle, 5.4), paint);
    canvas.drawPath(_capsule(kickAnkle, 5.2, kickToe, 4.6), paint);
  }
}
