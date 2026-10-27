"""Makes the app icons (iOS and Android) from the two big pictures of the mark of
the logo (the navy ball and the green 5, on white, like the splash).

The pictures are drawn from the vector logo of the splash:

  L3B_ICON_DIR=tool flutter test test/render_icon_test.dart
    -> tool/app_icon_full.png        the whole icon: the mark on white
       tool/app_icon_foreground.png  the mark alone, smaller, for Android's adaptive icon

and this script cuts them to every size it needs:

  iOS      ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png   (square, no alpha)
  Android  android/app/src/main/res/mipmap-*/ic_launcher.png     (rounded square)
           android/app/src/main/res/mipmap-*/ic_launcher_foreground.png   (adaptive)
           android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
           android/app/src/main/res/values/ic_launcher_background.xml   (white)

  pip install pillow
  python tool/make_icons.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FULL = ROOT / "tool" / "app_icon_full.png"
FOREGROUND = ROOT / "tool" / "app_icon_foreground.png"

BACKGROUND = "#FFFFFF"
CORNER = 0.18  # the corners of the plain Android icon, as a part of its size


def resized(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.LANCZOS)


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    print("wrote", path.relative_to(ROOT), image.size)


def rounded(image: Image.Image) -> Image.Image:
    """The picture with round corners (transparent outside them)."""
    size = image.size[0]
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=int(size * CORNER), fill=255
    )
    out = image.convert("RGBA")
    out.putalpha(mask)
    return out


def main() -> None:
    full = Image.open(FULL).convert("RGB")
    foreground = Image.open(FOREGROUND).convert("RGBA")

    # --- iOS: the square (it rounds the corners itself), no alpha ---
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for file in sorted(ios.glob("Icon-App-*.png")):
        size = Image.open(file).size[0]
        save(resized(full, size), file)

    # --- Android: the rounded square, for the phones without adaptive icons ---
    res = ROOT / "android/app/src/main/res"
    plain = rounded(full)
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in legacy.items():
        save(resized(plain, size), res / f"mipmap-{density}/ic_launcher.png")

    # --- Android: the adaptive icon, the mark over a white background ---
    # (No <monochrome> layer: the phones that tint the icons to the wallpaper
    # would turn the mark into one color, and lose the blue and the green.)
    adaptive = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for density, size in adaptive.items():
        save(
            resized(foreground, size),
            res / f"mipmap-{density}/ic_launcher_foreground.png",
        )
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
        f'    <color name="ic_launcher_background">{BACKGROUND}</color>\n'
        "</resources>\n"
    )
    print("wrote", xml.relative_to(ROOT), "and", colors.relative_to(ROOT))

    # A picture of the icon to look at (on grey, because the icon is white).
    preview = Image.new("RGB", (640, 640), (232, 236, 243))
    icon = resized(plain, 512)
    preview.paste(icon, (64, 64), icon)
    save(preview, ROOT / "docs/app_icon.png")


if __name__ == "__main__":
    main()
