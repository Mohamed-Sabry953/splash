"""Makes the app icons (iOS and Android) from tool/app_icon_source.jpg.

The source is a picture of the icon (a navy rounded square with the ball and the
green 5) on a white page. The picture is cut out, made large, and its three colors
(navy, white, green) are made clean with smooth edges, so that the icon is sharp
at 1024 px. Then it writes:

  iOS      ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png   (square, no alpha)
  Android  android/app/src/main/res/mipmap-*/ic_launcher.png     (rounded square)
           android/app/src/main/res/mipmap-*/ic_launcher_foreground.png   (adaptive)
           android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
           android/app/src/main/res/values/ic_launcher_background.xml

  pip install numpy pillow
  python tool/make_icons.py [tool/app_icon_source.jpg]
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "tool" / "app_icon_source.jpg"

NAVY = (10, 43, 96)
WHITE = (255, 255, 255)
GREEN = (142, 198, 63)
PALETTE = np.array([NAVY, WHITE, GREEN], dtype=np.float32)

BIG = 2048  # the working size
FOREGROUND_SCALE = 0.74  # how big the ball is in the adaptive icon (its safe zone)


def cut_out(image: Image.Image) -> Image.Image:
    """The rounded square of the picture."""
    a = np.asarray(image.convert("RGB")).astype(int)
    near = (
        (abs(a[:, :, 0] - NAVY[0]) < 40)
        & (abs(a[:, :, 1] - NAVY[1]) < 40)
        & (abs(a[:, :, 2] - NAVY[2]) < 45)
    )
    ys, xs = np.where(near)
    # (it is made square when it is made large: it is a square, give or take a pixel)
    return image.convert("RGB").crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def clean_labels(image: Image.Image) -> np.ndarray:
    """0 navy, 1 white, 2 green for every pixel; the edges are smoothed."""
    big = image.resize((BIG, BIG), Image.LANCZOS)
    a = np.asarray(big).astype(np.float32)
    distance = ((a[:, :, None, :] - PALETTE[None, None, :, :]) ** 2).sum(-1)
    label = distance.argmin(-1)
    # Round the corners of the shapes: blur each color, and the strongest wins.
    scores = []
    for k in range(3):
        mask = Image.fromarray(((label == k) * 255).astype(np.uint8))
        scores.append(np.asarray(mask.filter(ImageFilter.GaussianBlur(5))))
    return np.stack(scores, -1).argmax(-1)


def outside_of(label: np.ndarray) -> np.ndarray:
    """The white around the rounded square (not the white of the ball)."""
    # (the copy: a picture made from an array can not be drawn on)
    picture = Image.fromarray((label * 100).astype(np.uint8)).copy()
    for corner in [(0, 0), (BIG - 1, 0), (0, BIG - 1), (BIG - 1, BIG - 1)]:
        ImageDraw.floodfill(picture, corner, 255)
    return np.asarray(picture) == 255


def soft(mask: np.ndarray, radius: float = 2.5) -> np.ndarray:
    """A mask (bool) as an alpha (0 to 255) with soft edges."""
    image = Image.fromarray((mask * 255).astype(np.uint8))
    return np.asarray(image.filter(ImageFilter.GaussianBlur(radius))).astype(np.float32)


def paint(label: np.ndarray, outside: np.ndarray) -> np.ndarray:
    colors = np.array([NAVY, WHITE, GREEN], dtype=np.uint8)
    rgb = colors[label]
    rgb[outside] = NAVY
    return rgb


def resized(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.LANCZOS)


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    print("wrote", path.relative_to(ROOT), image.size)


def main() -> None:
    label = clean_labels(cut_out(Image.open(SOURCE)))
    outside = outside_of(label)

    # --- the square, for iOS (it rounds the corners itself) ---
    square = Image.fromarray(paint(label, outside), "RGB")
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for file in sorted(ios.glob("Icon-App-*.png")):
        size = Image.open(file).size[0]
        save(resized(square, size), file)

    # --- the rounded square, for the Android that has no adaptive icons ---
    rounded = square.convert("RGBA")
    alpha = 255 - soft(outside, 3)
    rounded.putalpha(Image.fromarray(alpha.astype(np.uint8)))
    res = ROOT / "android/app/src/main/res"
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in legacy.items():
        save(resized(rounded, size), res / f"mipmap-{density}/ic_launcher.png")

    # --- the adaptive icon: the ball and the 5 over a navy background ---
    ink = (label != 0) & ~outside  # white and green: what is not navy
    foreground = np.zeros((BIG, BIG, 4), dtype=np.uint8)
    foreground[:, :, :3] = paint(label, outside)
    foreground[:, :, 3] = soft(ink, 2.5).astype(np.uint8)
    foreground = Image.fromarray(foreground, "RGBA")
    # It sits in the middle, smaller, inside the part that is never cut away.
    canvas = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
    inner = int(BIG * FOREGROUND_SCALE)
    canvas.paste(resized(foreground, inner), ((BIG - inner) // 2, (BIG - inner) // 2))
    adaptive = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for density, size in adaptive.items():
        save(resized(canvas, size), res / f"mipmap-{density}/ic_launcher_foreground.png")

    # (No <monochrome> layer: with one, the phones that tint the icons to the
    # wallpaper (Android 13 and later, "themed icons") would turn it into a white
    # logo on a blue square, and lose the green and the white of the ball.)
    xml = res / "mipmap-anydpi-v26/ic_launcher.xml"
    xml.parent.mkdir(parents=True, exist_ok=True)
    xml.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    colors = res / "values/ic_launcher_background.xml"
    colors.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#0A2B60</color>\n'
        "</resources>\n"
    )
    print("wrote", xml.relative_to(ROOT), "and", colors.relative_to(ROOT))

    # A preview of the square, to look at.
    preview = ROOT / "docs/app_icon.png"
    save(resized(rounded, 512), preview)


if __name__ == "__main__":
    main()
