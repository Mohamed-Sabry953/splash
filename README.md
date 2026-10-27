# 5L3B splash

An animated splash for the 5L3B logo, in plain Flutter (no packages): everything is
drawn with a `CustomPainter` from the vector outline of the logo.

![preview](docs/splash_preview.gif)

## The story (3.9 s)

The logo shows, small and in the middle. The ball is thrown up; the letters turn into
dust, and the dust into a player, who kicks the ball into the goal and cheers; then the
player turns back into the letters, the ball comes home, and a shine goes over the logo.

| ms | what happens |
|---|---|
| 0–300 | the logo comes in |
| 360–500 | the ball crouches, and is thrown up to the top of the screen (it gets smaller as it goes) |
| 640–1260 | the letters dissolve into dust that flows into a player; the pitch and the goal appear |
| 1260–1620 | the ball falls, the player winds up |
| 1620–1920 | the kick (shake, ring, lines, a green streak behind the ball), and the ball is in the net: it ripples |
| 1760–2260 | the player jumps with both arms up |
| 2260–2940 | the player dissolves back into the letters, left to right |
| 2340–2960 | the ball leaves the net and comes home, growing; it lands with a ring and a few shards |
| 3040–3620 | a shine goes over the logo |
| 3900 | `onFinished` is called |

All the times are in `lib/splash/splash_timeline.dart`; where things are (the ground,
the goal, the player, the size of the logo) in `lib/splash/scene.dart`; the poses of the
player in `lib/splash/player.dart`.

## Use it in an app

Copy `lib/splash/` into the app and show the splash first:

```dart
L3bSplashScreen(
  onFinished: () => Navigator.of(context).pushReplacement(/* the app */),
  // haptics: false,   // no taps on the phone at the kick, the goal, ...
  // speed: 1.5,       // 1.5 times faster
)
```

- It makes the dust (4,600 dots) as it starts, before anything moves: about 0.1 s in
  debug mode, less in release.
- With the phone set to *reduce motion* it shows the logo at rest and calls `onFinished`
  after 0.7 s.
- `L3bLogoView(width: 260)` is the logo at rest, for the login page, the about page, etc.
- The background is white, so the native launch screen can stay white too (it already is
  in this project: `LaunchScreen.storyboard` on iOS, `launch_background.xml` on Android,
  in light and dark mode), and the first frame of the splash is blank: no jump.
  Android 12+ always shows its own splash with the app icon first; that can not be removed.

## How the letters become the player

`lib/splash/morph.dart` fills the letters with thousands of small squares (dust), and
fills the player with the same number. Every square of the letters is matched to one of
the player (left to right, top to bottom, green with green), and flows to it along a
curve. The way back is the same with the player of the end of the story.

## If the logo changes

```sh
pip install numpy scipy scikit-image pillow
python tool/vectorize.py tool/5l3b_logo.jpg tool/shapes.json      # traces the picture
python tool/gen_dart.py  tool/shapes.json lib/splash/logo_data.dart
```

`vectorize.py` cuts the picture into the pieces that move (ball patches, 5, stroke, L, 3, B)
and finds the piece of the ball that the 5 covers (the ball is whole while it flies). A
cleaner source (SVG) would make a sharper result than the 1600 px JPG.

## Look at any moment

```sh
L3B_FRAMES_DIR=/tmp/frames L3B_FRAMES=0,600,1260,1620,2400 flutter test test/render_frames_test.dart
L3B_FRAMES_DIR=/tmp/poses flutter test test/render_poses_test.dart     # the poses of the player
```

write `f00000.png`, … (`L3B_WIDTH` / `L3B_HEIGHT` change the screen size).
