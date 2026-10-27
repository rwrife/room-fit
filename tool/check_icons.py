"""Check generated platform icon sets without external packages."""
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "AppStore/icon.png"


def png_size(path):
    data = path.read_bytes()
    assert data[:16] == b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR", path
    return struct.unpack(">II", data[16:24])


def check():
    assert png_size(SOURCE) == (1024, 1024)
    for density, size in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                          ("xxhdpi", 144), ("xxxhdpi", 192)]:
        path = ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
        assert png_size(path) == (size, size), path

    directory = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    entries = json.loads((directory / "Contents.json").read_text())["images"]
    for entry in entries:
        scale = int(entry["scale"][0])
        size = float(entry["size"].split("x")[0])
        path = directory / entry["filename"]
        assert png_size(path) == (int(size * scale),) * 2, path
    marketing = directory / "Icon-App-1024x1024@1x.png"
    assert hashlib.sha256(marketing.read_bytes()).digest() == hashlib.sha256(SOURCE.read_bytes()).digest()

    ico = (ROOT / "windows/runner/resources/app_icon.ico").read_bytes()
    reserved, kind, count = struct.unpack_from("<HHH", ico)
    assert (reserved, kind) == (0, 1)
    sizes = set()
    for i in range(count):
        width, height, _, _, _, _, length, offset = struct.unpack_from("<BBBBHHII", ico, 6 + i * 16)
        assert width == height and offset + length <= len(ico)
        sizes.add(width or 256)
    assert {16, 24, 32, 48, 64, 128, 256} <= sizes, sizes
    print(f"OK: Android 5 densities, iOS {len(entries)} entries, Windows {sorted(sizes)}; marketing PNG matches source")


if __name__ == "__main__":
    check()
