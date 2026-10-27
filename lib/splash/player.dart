import 'dart:math' as math;
import 'dart:ui';

/// The footballer the letters turn into.
///
/// Every angle is in radians, measured from "straight down" and positive when
/// it swings to the front (the way the player faces). A leg or an arm hanging
/// down is 0; held out in front of the body, a quarter of a turn.
///
/// He is seen from the side; [yaw] turns him to face the viewer, and the
/// "side" angles spread his legs and arms sideways, which is what a person
/// facing the viewer shows.
class PlayerPose {
  const PlayerPose({
    this.lean = 0,
    this.headTilt = 0,
    this.kickThigh = 0,
    this.kickKnee = 0,
    this.kickFoot = _quarter,
    this.kickSide = 0,
    this.plantThigh = 0,
    this.plantKnee = 0,
    this.plantFoot = _quarter,
    this.plantFlat = 1,
    this.plantSide = 0,
    this.nearArm = 0,
    this.nearElbow = 0,
    this.nearArmSide = 0,
    this.farArm = 0,
    this.farElbow = 0,
    this.farArmSide = 0,
    this.roll = 0,
    this.yaw = 0,
    this.shout = 0,
    this.lift = 0,
    this.x = 0,
  });

  static const double _quarter = math.pi / 2;

  /// The body leans forward by this much (backwards when negative).
  final double lean;
  final double headTilt;

  /// The leg that kicks, nearest to the viewer: the angle of the thigh, how
  /// much the knee is bent (the shin goes back by that), the foot's angle from
  /// the shin, and how far the leg is spread out sideways.
  final double kickThigh;
  final double kickKnee;
  final double kickFoot;
  final double kickSide;

  /// The other leg, farther from the viewer. When [plantFlat] is 1 its foot
  /// is flat on the ground, whatever the leg does; at 0 it is [plantFoot]
  /// from the shin, like the other one.
  final double plantThigh;
  final double plantKnee;
  final double plantFoot;
  final double plantFlat;
  final double plantSide;

  /// An arm: the angle of its upper part, how much the elbow bends to the
  /// front, and how far the arm is spread out sideways.
  final double nearArm;
  final double nearElbow;
  final double nearArmSide;
  final double farArm;
  final double farElbow;
  final double farArmSide;

  /// The whole body turned backwards about the hip: a quarter of a turn
  /// leaves it lying on its back.
  final double roll;

  /// The body turned about the vertical: 0 shows him from the side, a quarter
  /// of a turn shows him from the front.
  final double yaw;

  /// How wide he opens his mouth to shout (0 to 1).
  final double shout;

  /// How high the hip is above where it is when the player stands (negative:
  /// lower).
  final double lift;

  /// Where the hip is, from where the player stands.
  final double x;

  /// The same pose turned to [yaw].
  PlayerPose withYaw(double yaw) => PlayerPose(
    lean: lean,
    headTilt: headTilt,
    kickThigh: kickThigh,
    kickKnee: kickKnee,
    kickFoot: kickFoot,
    kickSide: kickSide,
    plantThigh: plantThigh,
    plantKnee: plantKnee,
    plantFoot: plantFoot,
    plantFlat: plantFlat,
    plantSide: plantSide,
    nearArm: nearArm,
    nearElbow: nearElbow,
    nearArmSide: nearArmSide,
    farArm: farArm,
    farElbow: farElbow,
    farArmSide: farArmSide,
    roll: roll,
    yaw: yaw,
    shout: shout,
    lift: lift,
    x: x,
  );

  PlayerPose copyWith({double? lift, double? x}) => PlayerPose(
    lean: lean,
    headTilt: headTilt,
    kickThigh: kickThigh,
    kickKnee: kickKnee,
    kickFoot: kickFoot,
    kickSide: kickSide,
    plantThigh: plantThigh,
    plantKnee: plantKnee,
    plantFoot: plantFoot,
    plantFlat: plantFlat,
    plantSide: plantSide,
    nearArm: nearArm,
    nearElbow: nearElbow,
    nearArmSide: nearArmSide,
    farArm: farArm,
    farElbow: farElbow,
    farArmSide: farArmSide,
    roll: roll,
    yaw: yaw,
    shout: shout,
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
      kickSide: l(a.kickSide, b.kickSide),
      plantThigh: l(a.plantThigh, b.plantThigh),
      plantKnee: l(a.plantKnee, b.plantKnee),
      plantFoot: l(a.plantFoot, b.plantFoot),
      plantFlat: l(a.plantFlat, b.plantFlat),
      plantSide: l(a.plantSide, b.plantSide),
      nearArm: l(a.nearArm, b.nearArm),
      nearElbow: l(a.nearElbow, b.nearElbow),
      nearArmSide: l(a.nearArmSide, b.nearArmSide),
      farArm: l(a.farArm, b.farArm),
      farElbow: l(a.farElbow, b.farElbow),
      farArmSide: l(a.farArmSide, b.farArmSide),
      roll: l(a.roll, b.roll),
      yaw: l(a.yaw, b.yaw),
      shout: l(a.shout, b.shout),
      lift: l(a.lift, b.lift),
      x: l(a.x, b.x),
    );
  }
}

double _rad(double degrees) => degrees * math.pi / 180;

/// The poses of the story, in the order they come. The player has his back to
/// where the ball goes: he looks up at the ball, jumps, falls backwards and
/// kicks it over his head (a bicycle kick), lands on his back, and gets up for
/// the celebration of Cristiano Ronaldo: a jump with a turn in the air to face
/// the crowd, a landing with the legs wide apart, the arms down and out, the
/// chest out and the head up, shouting "Siuuu".
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

  /// In the air in the middle of the turn, half way from the side to the
  /// front: the legs together and straight, the arms a little out.
  static final PlayerPose siuAir = PlayerPose(
    lean: _rad(-4),
    headTilt: _rad(-16),
    kickThigh: _rad(10),
    kickKnee: _rad(18),
    kickFoot: _rad(40),
    kickSide: _rad(8),
    plantThigh: _rad(-4),
    plantKnee: _rad(6),
    plantFoot: _rad(40),
    plantFlat: 0,
    plantSide: _rad(8),
    nearArm: _rad(10),
    nearElbow: _rad(6),
    nearArmSide: _rad(22),
    farArm: _rad(6),
    farElbow: _rad(6),
    farArmSide: _rad(22),
    yaw: _rad(52),
    shout: 0.4,
    lift: 40,
    x: 14,
  );

  /// "Siuuu": facing the crowd, the legs wide apart, the arms straight down
  /// and out, the chest out, the head up, the mouth open.
  static final PlayerPose siu = PlayerPose(
    lean: _rad(-6),
    headTilt: _rad(-22),
    kickThigh: _rad(0),
    kickKnee: _rad(0),
    kickSide: _rad(25),
    plantThigh: _rad(0),
    plantKnee: _rad(0),
    plantSide: _rad(25),
    nearArm: _rad(0),
    nearElbow: _rad(0),
    nearArmSide: _rad(36),
    farArm: _rad(0),
    farElbow: _rad(0),
    farArmSide: _rad(36),
    yaw: _rad(90),
    shout: 1,
    x: 14,
  );
}

/// The shape of a body part, and what it is made of.
class BodyPart {
  const BodyPart(this.path, this.role, {this.shaded = true});

  final Path path;

  /// Which color it takes (see [PlayerRig.colors]).
  final BodyRole role;

  /// Whether the light falls on it (a little lighter on one side, a little
  /// darker on the other); the small things (eyes, trims, teeth) are flat.
  final bool shaded;
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

  /// The darker skin of the nose and the ears.
  shade,

  /// The navy bands of the collar, the sleeves and the socks.
  trim,

  /// The sole of a boot, near and far.
  sole,
  farSole,

  /// The teeth.
  teeth,
}

/// A point of the body in three directions: [xy] is where it is as seen from
/// the side (x to the front, y down), and [z] how far it is to the near side.
class _P {
  const _P(this.xy, [this.z = 0]);

  final Offset xy;
  final double z;

  _P operator +(_P other) => _P(xy + other.xy, z + other.z);
}

/// Where the parts of the body are for a pose, and the shapes to paint.
///
/// The player is built in his own space (x to the front, y down, z to the
/// near side, the hip at the origin), then turned about the hip by the roll
/// (backwards) and by the yaw (to face the viewer), flipped when he faces
/// left, and put where he is.
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

  /// Half the width of the hips, and of the shoulders.
  static const double hipHalf = 5;
  static const double shoulderHalf = 11;

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

  /// Where the mouth is.
  late final Offset mouth;

  /// All the parts, from the back to the front.
  late final List<BodyPart> parts;

  /// The parts of the leg that kicks, for the trail behind it.
  late final List<Path> kickingLeg;

  late final Offset _origin;
  late final double _cosRoll, _sinRoll, _cosYaw, _sinYaw;

  /// How much of the front he shows: 0 from the side, 1 from the front.
  double get _front => _sinYaw;

  /// A step of [length] along a limb at [angle] to the front and [side] to
  /// the outside, to the near side or the far one ([sign] is 1 or -1).
  static _P _step(double length, double angle, double side, double sign) {
    return _P(
      Offset(
            math.sin(angle) * math.cos(side),
            math.cos(angle) * math.cos(side),
          ) *
          length,
      sign * math.sin(side) * length,
    );
  }

  /// A point of the player's own space, where it is on the scene.
  Offset _w(_P p) {
    // Backwards about the hip...
    final x = _cosRoll * p.xy.dx - _sinRoll * p.xy.dy;
    final y = _sinRoll * p.xy.dx + _cosRoll * p.xy.dy;
    // ...then turned to face the viewer, flipped, and put in place.
    final seen = x * _cosYaw - p.z * _sinYaw;
    return _origin + Offset(seen * facing, y);
  }

  void _build() {
    final p = pose;
    _cosRoll = math.cos(-p.roll);
    _sinRoll = math.sin(-p.roll);
    _cosYaw = math.cos(p.yaw);
    _sinYaw = math.sin(p.yaw);

    // The player stands on the far leg: that decides how high the hip is.
    final plantShin = p.plantThigh - p.plantKnee;
    final legHeight =
        (thigh * math.cos(p.plantThigh) + shin * math.cos(plantShin)) *
        math.cos(p.plantSide);
    _origin = Offset(p.x, ground - ankleHeight - legHeight - p.lift);

    final up = Offset(math.sin(p.lean), -math.cos(p.lean));
    final headUp = Offset(
      math.sin(p.lean + p.headTilt),
      -math.cos(p.lean + p.headTilt),
    );
    final front = Offset(-headUp.dy, headUp.dx);

    // --- the joints, in the space of the body ----------------------------
    const hipL = _P(Offset.zero);
    const hipNear = _P(Offset.zero, hipHalf);
    const hipFar = _P(Offset.zero, -hipHalf);
    final shoulderL = _P(up * (torso - 5));
    final shoulderNear = _P(up * (torso - 5), shoulderHalf);
    final shoulderFar = _P(up * (torso - 5), -shoulderHalf);
    final headL = _P(up * torso + headUp * (headRadius + 5));

    final plantKneeL = hipFar + _step(thigh, p.plantThigh, p.plantSide, -1);
    final plantAnkleL = plantKneeL + _step(shin, plantShin, p.plantSide, -1);
    final plantFootAngle =
        plantShin +
        p.plantFoot +
        (math.pi / 2 - plantShin - p.plantFoot) * p.plantFlat;
    final plantToeL =
        plantAnkleL +
        _P(Offset(math.sin(plantFootAngle), math.cos(plantFootAngle)) * foot);

    final kickShin = p.kickThigh - p.kickKnee;
    final kickKneeL = hipNear + _step(thigh, p.kickThigh, p.kickSide, 1);
    final kickAnkleL = kickKneeL + _step(shin, kickShin, p.kickSide, 1);
    final kickFootAngle = kickShin + p.kickFoot;
    final kickToeL =
        kickAnkleL +
        _P(Offset(math.sin(kickFootAngle), math.cos(kickFootAngle)) * foot);

    final nearElbowL =
        shoulderNear + _step(upperArm, p.nearArm, p.nearArmSide, 1);
    final nearHandL =
        nearElbowL + _step(foreArm, p.nearArm + p.nearElbow, p.nearArmSide, 1);
    final farElbowL = shoulderFar + _step(upperArm, p.farArm, p.farArmSide, -1);
    final farHandL =
        farElbowL + _step(foreArm, p.farArm + p.farElbow, p.farArmSide, -1);

    hip = _w(hipL);
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
      hipL: hipFar,
      kneeL: plantKneeL,
      ankleL: plantAnkleL,
      toeL: plantToeL,
      skin: BodyRole.farSkin,
      shorts: BodyRole.farShorts,
      sock: BodyRole.farSock,
      boot: BodyRole.farBoot,
      sole: BodyRole.farSole,
      sign: -1,
      toeOut: p.plantSide,
    );
    final nearLeg = _leg(
      hipL: hipNear,
      kneeL: kickKneeL,
      ankleL: kickAnkleL,
      toeL: kickToeL,
      skin: BodyRole.skin,
      shorts: BodyRole.shorts,
      sock: BodyRole.sock,
      boot: BodyRole.boot,
      sole: BodyRole.sole,
      sign: 1,
      toeOut: p.kickSide,
    );

    // The body is deep from the side and wide from the front: from the front
    // the chest is broad, the waist narrow and the hips a little wider.
    List<double> body(List<double> side, List<double> front) => [
      for (var i = 0; i < side.length; i++) _lerp(side[i], front[i], _front),
    ];
    final shirtWidth = body(
      const [10.4, 9.4, 10.4, 12.4, 13.2],
      const [14.6, 13.0, 15.6, 19.6, 20.6],
    );
    final pelvisWidth = body(const [10.4, 10.6], const [16.6, 15.6]);

    const sleeve = 0.55;
    final neckBase = _w(_P(up * (torso - 9)));
    final spine = _unit(shoulder - hip);
    final across = Offset(-spine.dy, spine.dx);
    final headParts = _head(headL, headUp, front);
    // From the side the near leg is in front of the body; from the front the
    // shirt hangs over the shorts, and the legs are behind it.
    final legsBehind = _front > 0.5;
    // The collar: a navy band round the neck. From the side it is a short bar
    // across the neck; from the front it is a U, with the skin of the chest in
    // it.
    final collarHalf = _lerp(4.4, 7.2, _front);
    final collarAt = shoulder + spine * 3.4;
    final dip = 3.6 * _front;
    final collar = Path();
    const collarSteps = 8;
    for (var i = 0; i < collarSteps; i++) {
      Offset at(int k) {
        final t = -1 + 2 * k / collarSteps;
        return collarAt +
            across * (collarHalf * t) -
            spine * (dip * (1 - t * t));
      }

      collar.addPath(_tube(at(i), at(i + 1), const [1.2, 1.2]), Offset.zero);
    }
    final neckOpening = _tube(
      collarAt - spine * (dip + 0.4),
      collarAt + spine * 3,
      [collarHalf * 0.5 * _front + 0.1, collarHalf * 0.62 * _front + 0.1],
    );
    parts = [
      // The arm that is far.
      ..._arm(
        shoulderFar,
        farElbowL,
        farHandL,
        BodyRole.farSkin,
        BodyRole.farShirt,
        sleeve,
      ),
      ...farLeg,
      if (legsBehind) ...nearLeg,
      // The neck and the body.
      BodyPart(_tube(neckBase, head, const [4.7, 4.3, 4.5]), BodyRole.farSkin),
      BodyPart(
        _tube(
          hip - spine * 3,
          hip + spine * 8,
          pelvisWidth,
          capA: _lerp(1, 0.5, _front),
        ),
        BodyRole.shorts,
      ),
      BodyPart(
        _tube(
          hip,
          shoulder,
          shirtWidth,
          capA: _lerp(1, 0.38, _front),
          capB: 0.5,
        ),
        BodyRole.shirt,
      ),
      if (_front > 0.15) BodyPart(neckOpening, BodyRole.skin),
      BodyPart(collar, BodyRole.trim, shaded: false),
      headParts.farEar,
      ...headParts.parts,
      // The leg and the arm that are near.
      if (!legsBehind) ...nearLeg,
      ..._arm(
        shoulderNear,
        nearElbowL,
        nearHandL,
        BodyRole.skin,
        BodyRole.shirt,
        sleeve,
      ),
    ];
    mouth = headParts.mouth;
    kickingLeg = [
      for (final part in nearLeg)
        if (part.role != BodyRole.shorts) part.path,
    ];
  }

  /// A leg: the shorts over the top of the thigh, the skin of the knee, the
  /// sock over the lower shin (with a band at its top), and the boot.
  List<BodyPart> _leg({
    required _P hipL,
    required _P kneeL,
    required _P ankleL,
    required _P toeL,
    required BodyRole skin,
    required BodyRole shorts,
    required BodyRole sock,
    required BodyRole boot,
    required BodyRole sole,
    required double sign,
    required double toeOut,
  }) {
    final top = _w(hipL);
    final knee = _w(kneeL);
    final ankle = _w(ankleL);
    final endShorts = Offset.lerp(top, knee, 0.46)!;
    final sockTop = Offset.lerp(knee, ankle, 0.42)!;
    final band = Offset.lerp(sockTop, ankle, 0.1)!;
    final (bootPath, solePath) = _boot(ankleL, toeL, sign, toeOut);
    return [
      BodyPart(_tube(top, knee, const [9.4, 9.2, 7.9, 6.5]), skin),
      BodyPart(_tube(knee, ankle, const [6.3, 6.9, 5.7, 4.2]), skin),
      BodyPart(_tube(sockTop, ankle, const [5.9, 5.6, 4.6], capA: 0.4), sock),
      BodyPart(
        _tube(sockTop, band, const [6.0, 6.0], capA: 0.2, capB: 0.2),
        BodyRole.trim,
        shaded: false,
      ),
      BodyPart(
        _tube(top, endShorts, const [9.8, 9.3, 9.0], capB: 0.25),
        shorts,
      ),
      BodyPart(bootPath, boot),
      BodyPart(solePath, sole, shaded: false),
    ];
  }

  /// A boot: a heel, a sole and a toe, from the ankle to the toe, and the
  /// sole of it. It is as wide as a foot is: seen from the front it is a
  /// small block, not a line, and the toe turns out as the legs spread.
  (Path, Path) _boot(_P ankleL, _P toeL, double sign, double toeOut) {
    final f = toeL.xy - ankleL.xy;
    final length = f.distance;
    final u = f / length; // along the foot
    final v = Offset(-u.dy, u.dx); // towards the sole
    final outline = <(double, double)>[
      (-4.4, -4.6),
      (-5.2, 3.2),
      (-1.5, 5.2),
      (length - 2.5, 5.2),
      (length + 2.2, 3.0),
      (length + 2.8, 0.2),
      (length - 2.0, -3.6),
      (3.5, -4.8),
    ];
    final sole = <(double, double)>[
      (-5.2, 3.7),
      (-1.5, 5.2),
      (length - 2.5, 5.2),
      (length + 2.2, 3.7),
      (length + 2.3, 2.9),
      (-5.3, 2.7),
    ];
    // The outline on both sides of the foot, seen from where we are: the toe
    // goes farther out than the heel when the foot is turned out.
    final out = sign * math.sin(toeOut);
    List<Offset> points(List<(double, double)> shape) => [
      for (final side in const [-4.0, 4.0])
        for (final (along, across) in shape)
          _w(
            _P(
              ankleL.xy + u * along + v * across,
              ankleL.z + side + out * along,
            ),
          ),
    ];
    return (_hull(points(outline)), _hull(points(sole)));
  }

  /// The smallest convex shape that holds [points].
  static Path _hull(List<Offset> points) {
    final sorted = [...points]
      ..sort(
        (a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy),
      );
    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    final lower = <Offset>[];
    for (final p in sorted) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final upper = <Offset>[];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }
    lower.removeLast();
    upper.removeLast();
    final hull = [...lower, ...upper];
    final path = Path()..moveTo(hull.first.dx, hull.first.dy);
    for (final p in hull.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// An arm: skin, a fist, and the sleeve of the shirt over the top of it,
  /// with a navy band at the end of the sleeve.
  List<BodyPart> _arm(
    _P shoulderL,
    _P elbowL,
    _P handL,
    BodyRole skin,
    BodyRole shirt,
    double sleeve,
  ) {
    final s = _w(shoulderL);
    final e = _w(elbowL);
    final h = _w(handL);
    final along = _unit(h - e);
    Offset onArm(double t) => Offset.lerp(s, e, t)!;
    return [
      BodyPart(_tube(s, e, const [5.5, 5.3, 4.6]), skin),
      BodyPart(_tube(e, h, const [4.6, 4.8, 3.7]), skin),
      BodyPart(
        _tube(h - along * 0.5, h + along * 3.2, const [3.7, 4.5, 3.9]),
        skin,
      ),
      BodyPart(
        _tube(s, onArm(sleeve), const [6.8, 6.4, 5.9], capB: 0.3),
        shirt,
      ),
      BodyPart(
        _tube(
          onArm(sleeve - 0.07),
          onArm(sleeve + 0.01),
          const [5.9, 5.9],
          capA: 0.2,
          capB: 0.2,
        ),
        BodyRole.trim,
        shaded: false,
      ),
    ];
  }

  /// The head: skin, ears, a nose, brows and an eye or two, hair over the top
  /// and the back (swept up at the front), and a mouth that opens to shout.
  /// The ear that is far goes behind the head.
  ({List<BodyPart> parts, BodyPart farEar, Offset mouth}) _head(
    _P headL,
    Offset up,
    Offset front,
  ) {
    final c = _w(headL);
    // Where a point of the head is: [f] to the front, [u] up, [z] to the near
    // side, from its middle.
    Offset at(double f, double u, double z) =>
        _w(_P(headL.xy + front * f + up * u, z));
    final r = headRadius;
    final upScreen = _unit(at(0, 1, 0) - c);
    final frontScreen = _frontOnScreen(front, upScreen);

    // The skull: an egg with the chin at the narrow end.
    final skull = _tube(c + upScreen * (0.04 * r), c - upScreen * (0.22 * r), [
      0.96 * r,
      r,
      0.84 * r,
    ]);

    // The hair: from over the forehead round the top to the nape; seen from
    // the front it is a cap from ear to ear. It is swept up over the
    // forehead, and a little higher at the crown from the front.
    final towardsFront = _lerp(_rad(60), _rad(70), _front);
    final towardsBack = _lerp(_rad(120), _rad(70), _front);
    // From the front the hair stops at the hairline, above the eyes and the
    // mouth; from the side it comes down to the middle of the head.
    final hairline = c + upScreen * (0.42 * r * _front);
    final hair = Path()..moveTo(hairline.dx, hairline.dy);
    const steps = 18;
    for (var i = 0; i <= steps; i++) {
      final a = -towardsBack + (towardsFront + towardsBack) * i / steps;
      final dir = frontScreen * math.sin(a) + upScreen * math.cos(a);
      final quiff =
          2.8 *
          math.exp(-math.pow((a - _rad(30)) / _rad(20), 2)) *
          (1 - _front);
      final crown = 1.8 * _front * math.exp(-math.pow(a / _rad(28), 2));
      final point = c + dir * (r + 0.7 + quiff + crown);
      hair.lineTo(point.dx, point.dy);
    }
    hair.close();

    final nearEar = at(-0.12 * r, 0, 0.98 * r);
    final farEar = at(-0.12 * r, 0, -0.98 * r);
    final eyeNear = at(0.78 * r, -0.18 * r, 0.36 * r);
    final eyeFar = at(0.78 * r, -0.18 * r, -0.36 * r);
    final nose = at(0.94 * r, -0.46 * r, 0);
    final mouthAt = at(0.58 * r, -0.8 * r, 0);
    final mouthWidth = 2 + 3.6 * pose.shout;
    final mouthHeight = 1.4 + 4.4 * pose.shout;
    final showFar = _front > 0.35;

    return (
      parts: [
        BodyPart(skull, BodyRole.skin),
        BodyPart(_capsule(nearEar, 2.4, nearEar, 2.4), BodyRole.shade),
        BodyPart(hair, BodyRole.hair),
        BodyPart(_capsule(nose, 1.6, nose, 1.6), BodyRole.shade, shaded: false),
        // The hair comes down in front of the ears, seen from the front.
        if (_front > 0.75)
          for (final side in const [1.0, -1.0])
            BodyPart(
              _tube(
                at(0.12 * r, 0.3 * r, 0.93 * r * side),
                at(0.12 * r, -0.12 * r, 0.93 * r * side),
                const [1.2, 1.0],
              ),
              BodyRole.hair,
              shaded: false,
            ),
        BodyPart(
          _capsule(eyeNear, 1.25, eyeNear, 1.25),
          BodyRole.hair,
          shaded: false,
        ),
        if (showFar)
          BodyPart(
            _capsule(eyeFar, 1.25, eyeFar, 1.25),
            BodyRole.hair,
            shaded: false,
          ),
        if (_front > 0.45 && pose.shout > 0.05) ...[
          BodyPart(
            Path()..addOval(
              Rect.fromCenter(
                center: mouthAt,
                width: mouthWidth,
                height: mouthHeight,
              ),
            ),
            BodyRole.hair,
            shaded: false,
          ),
          if (pose.shout > 0.55)
            BodyPart(
              Path()..addOval(
                Rect.fromCenter(
                  center: mouthAt + upScreen * (mouthHeight * 0.24),
                  width: mouthWidth * 0.7,
                  height: mouthHeight * 0.26,
                ),
              ),
              BodyRole.teeth,
              shaded: false,
            ),
        ],
      ],
      farEar: BodyPart(_capsule(farEar, 2.4, farEar, 2.4), BodyRole.shade),
      mouth: mouthAt,
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static Offset _unit(Offset v) {
    final d = v.distance;
    return d < 1e-6 ? const Offset(0, -1) : v / d;
  }

  /// Which way the face looks on the screen, across the way the head is up.
  /// From the front it looks at us: any side will do, it is the same.
  Offset _frontOnScreen(Offset front, Offset upScreen) {
    final seen = _w(_P(front)) - _w(const _P(Offset.zero));
    if (_cosYaw.abs() > 0.2 && seen.distance > 1e-6) return _unit(seen);
    final across = Offset(-upScreen.dy, upScreen.dx);
    return across.dx * facing >= 0 ? across : -across;
  }

  /// A smooth bar from [a] to [b]. [radii] are how wide it is (half of it)
  /// at points spread along it from end to end, so that it can swell like a
  /// muscle; its ends are rounded, [capA] and [capB] times as far as they are
  /// wide (less than 1 makes them flatter).
  static Path _tube(
    Offset a,
    Offset b,
    List<double> radii, {
    double capA = 1,
    double capB = 1,
  }) {
    final d = b - a;
    final length = d.distance;
    if (length < 0.001) {
      return Path()..addOval(Rect.fromCircle(center: a, radius: radii.first));
    }
    final u = d / length;
    final n = Offset(-u.dy, u.dx);

    // A smooth curve through the radii (Catmull-Rom).
    double radiusAt(double t) {
      final x = t * (radii.length - 1);
      final i = x.floor().clamp(0, radii.length - 2);
      final f = x - i;
      double at(int k) => radii[k.clamp(0, radii.length - 1)];
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      return 0.5 *
          (2 * p1 +
              (p2 - p0) * f +
              (2 * p0 - 5 * p1 + 4 * p2 - p3) * f * f +
              (3 * p1 - p0 - 3 * p2 + p3) * f * f * f);
    }

    const perSegment = 5;
    const arc = 8;
    final count = (radii.length - 1) * perSegment;
    final path = Path();
    final right = <Offset>[];
    for (var i = 0; i <= count; i++) {
      final t = i / count;
      final c = a + d * t;
      final r = radiusAt(t);
      final p = c + n * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      right.add(c - n * r);
    }
    // Round the end at b, from one side to the other.
    final rb = radii.last;
    for (var k = 1; k < arc; k++) {
      final angle = math.pi * k / arc;
      final p =
          b + n * (rb * math.cos(angle)) + u * (rb * capB * math.sin(angle));
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    // And the end at a.
    final ra = radii.first;
    for (var k = 1; k < arc; k++) {
      final angle = math.pi * k / arc;
      final p =
          a - n * (ra * math.cos(angle)) - u * (ra * capA * math.sin(angle));
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
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
    BodyRole.shade: Color(0xFFCF9068),
    BodyRole.trim: Color(0xFF0A2B60),
    BodyRole.sole: Color(0xFF2160C0),
    BodyRole.farSole: Color(0xFF194B99),
    BodyRole.teeth: Color(0xFFFFFFFF),
  };

  /// The color of a part: what is far is a shade darker, unless he faces us,
  /// when nothing is farther than the rest.
  Color colorOf(BodyRole role) {
    final near = switch (role) {
      BodyRole.farSkin => BodyRole.skin,
      BodyRole.farShirt => BodyRole.shirt,
      BodyRole.farShorts => BodyRole.shorts,
      BodyRole.farSock => BodyRole.sock,
      BodyRole.farBoot => BodyRole.boot,
      BodyRole.farSole => BodyRole.sole,
      _ => role,
    };
    if (near == role || _front <= 0) return colors[role]!;
    return Color.lerp(colors[role], colors[near], _front)!;
  }

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
      final color = colorOf(part.role);
      final shader = part.shaded ? _lit(part.path.getBounds(), color) : null;
      paint
        ..color = color
        ..shader = shader;
      canvas.drawPath(part.path, paint);
      // The boots and the hair have corners: they are rounded by an outline.
      if (part.role == BodyRole.boot ||
          part.role == BodyRole.farBoot ||
          part.role == BodyRole.hair) {
        stroke
          ..color = color
          ..shader = shader;
        canvas.drawPath(part.path, stroke);
      }
    }
    if (number != null) _paintNumber(canvas, number);
    if (alpha < 1) canvas.restore();
  }

  /// Where the light comes from: the top left of the screen.
  static const Offset _light = Offset(-0.55, -0.83);

  /// [color] a little lighter on the side of the light and a little darker on
  /// the other, across [bounds]: it makes the flat shapes look round.
  static Shader _lit(Rect bounds, Color color) {
    final half =
        (bounds.width * _light.dx.abs() + bounds.height * _light.dy.abs()) / 2;
    return Gradient.linear(
      bounds.center + _light * half,
      bounds.center - _light * half,
      [
        Color.lerp(color, const Color(0xFFFFFFFF), 0.14)!,
        color,
        Color.lerp(color, const Color(0xFF06122B), 0.2)!,
      ],
      const [0, 0.42, 1],
    );
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
