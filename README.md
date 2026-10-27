# 5L3B splash

An animated splash for the 5L3B logo, in plain Flutter (no packages): everything is
drawn with a `CustomPainter` from the vector outline of the logo.

![preview](docs/splash_preview.gif)

## The story (4.35 s)

The logo shows, small and in the middle. The ball is thrown up; the letters turn into
dust, and the dust into a player, who has his back to where the ball will go. He looks up
at the ball, jumps, goes over backwards and kicks it over his head (a bicycle kick); the
ball flies out of the screen on the right. He lands on his back, gets up, crouches and
jumps, turning in the air to face us, and lands with his legs wide, his arms down and out,
his chest out and his head up, shouting "Siuuu" (Ronaldo's celebration). Then he turns
back into the letters, the ball comes in from the left and lands on the logo, and a shine
goes over the logo.

| ms | what happens |
|---|---|
| 0–300 | the logo comes in: the 5, then the letters one after the other, each rising into its place, and the stroke of the 5 is drawn from its start to its tip |
| 360–500 | the ball crouches, and is thrown up to the top of the screen (it gets smaller as it goes) |
| 640–1260 | the letters dissolve into dust that flows into a player (skin, hair, kit) |
| 1260–1560 | he crouches, jumps and starts to go over backwards (the far leg swings up first) |
| 1650 | the kick: the other leg whips over his head and meets the ball (shake, ring, lines, a green streak behind the ball) |
| 1650–1870 | the ball flies to the right, stretched along the shot at first, nearly flat and high over him, and leaves the screen; he falls on his back |
| 1920–2110 | he gets up and crouches, ready to jump |
| 2110–2470 | the jump: he turns in the air to face us and moves to the middle of the screen, his legs open as he comes down |
| 2470–2640 | "Siuuu": he lands in the middle of the screen with his knees bent and straightens up, his legs wide, arms down and out, chest out, head up and his mouth open; shake, rings and shards on the ground, rays over his head, a soft green light behind him, a burst of paper from behind his shoulders, and the camera pushes in (and in slowly while he shouts) |
| 2740–3400 | he dissolves back into the letters, left to right |
| 2960–3420 | the ball comes in from the left, high, and falls on the logo, growing as it comes near; it lands with a ring and a few shards, a small bounce of the logo, and the 5 is pressed into the ball at that moment |
| 3500–4080 | a shine goes over the logo, and little stars of light flash on it as it passes |
| 4350 | `onFinished` is called |

All the times are in `lib/splash/splash_timeline.dart`; where things are (the ground
the player stands on, the size of the logo) in `lib/splash/scene.dart`; where the ball is at every moment in `lib/splash/ball_track.dart`; the poses of the
player in `lib/splash/player.dart` (`PlayerPoses`: ready, crouch, takeOff, scissors,
strike, fall, lying, siuAir, siuLand, siu).

## Use it in an app

Copy `lib/splash/` into the app and show the splash first:

```dart
L3bSplashScreen(
  onFinished: () => Navigator.of(context).pushReplacement(/* the app */),
  // haptics: false,   // no taps on the phone when the ball is thrown, at the kick, at "Siuuu", ...
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

## The app icon

The icon of the app (the ball and the green 5, on a navy rounded square) is made from
`tool/app_icon_source.jpg`:

```sh
pip install numpy pillow
python tool/make_icons.py      # iOS (all the sizes), Android (adaptive and plain)
```

![icon](docs/app_icon.png)

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
L3B_FRAMES_DIR=/tmp/frames L3B_FRAMES=0,600,1260,1650,2400 flutter test test/render_frames_test.dart
L3B_FRAMES_DIR=/tmp/poses flutter test test/render_poses_test.dart     # the poses of the player
```

write `f00000.png`, … (`L3B_WIDTH` / `L3B_HEIGHT` change the screen size).
