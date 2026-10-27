# 5L3B splash

An animated splash for the 5L3B logo, in plain Flutter (no packages): everything is
drawn with a `CustomPainter` from the vector outline of the logo.

![preview](docs/splash_preview.gif)

## The story (3.4 s)

| ms | what happens |
|---|---|
| 120–1150 | the ball is dribbled in from the left: three hops, squash & stretch, a trail, a shadow; it lands with a ring on the ground and a few shards |
| 1250–1770 | the **5** drops from above and is pressed into the gap the ball has (the logo's own gap), with a shake, a ring and a burst |
| 1560–1990 | the top bar of the 5 shoots to the right, with speed lines and a glowing tip |
| 1600–2220 | **L**, **3**, **B** slide in one after the other, slanted, with trails |
| 2250–2900 | a shine sweeps over the logo |
| 2900–3400 | the logo rests, then `onFinished` is called |

All the times are in `lib/splash/splash_timeline.dart`.

## Use it in an app

Copy `lib/splash/` into the app and show the splash first:

```dart
L3bSplashScreen(
  onFinished: () => Navigator.of(context).pushReplacement(/* the app */),
  // haptics: false,   // no taps on the phone at the landings
  // speed: 1.5,       // 1.5 times faster
)
```

- With the phone set to *reduce motion* it shows the logo at rest and calls `onFinished`
  after 0.7 s.
- `L3bLogoView(width: 260)` is the logo at rest, for the login page, the about page, etc.
- The background is white, so the native launch screen can stay white too (it already is
  in this project: `LaunchScreen.storyboard` on iOS, `launch_background.xml` on Android,
  in light and dark mode), and the first frame of the splash is blank: no jump.
  Android 12+ always shows its own splash with the app icon first; that can not be removed.

## If the logo changes

```sh
pip install numpy scipy scikit-image pillow
python tool/vectorize.py tool/5l3b_logo.jpg tool/shapes.json      # traces the picture
python tool/gen_dart.py  tool/shapes.json lib/splash/logo_data.dart
```

`vectorize.py` cuts the picture into the pieces that move (ball patches, 5, stroke, L, 3, B)
and finds the piece of the ball that the 5 covers. A cleaner source (SVG) would make a
sharper result than the 1600 px JPG.

## Look at any moment

```sh
L3B_FRAMES_DIR=/tmp/frames L3B_FRAMES=0,600,1150,1390,2400 flutter test test/render_frames_test.dart
```

writes `f00000.png`, … (`L3B_WIDTH` / `L3B_HEIGHT` change the screen size).
