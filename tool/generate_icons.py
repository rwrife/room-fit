from PIL import Image
import os
import shutil
import sys

def main():
    base = sys.argv[1]
    icon_src = os.path.join(base, "AppStore", "icon.png")
    if not os.path.isfile(icon_src):
        print(f"Missing {icon_src}")
        sys.exit(1)

    img = Image.open(icon_src).convert("RGB")
    print(f"Loaded {icon_src}: {img.size}, mode={img.mode}")

    # 1. Android mipmap icons
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, dim in android_sizes.items():
        dst_dir = os.path.join(base, "android", "app", "src", "main", "res", folder)
        os.makedirs(dst_dir, exist_ok=True)
        dst_path = os.path.join(dst_dir, "ic_launcher.png")
        resized = img.resize((dim, dim), Image.Resampling.LANCZOS)
        resized.save(dst_path, "PNG")
        print(f"Wrote Android {dst_path} ({dim}x{dim})")

    # 2. iOS asset catalog icons
    # From Contents.json:
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ios_dir = os.path.join(base, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    for filename, dim in ios_sizes.items():
        dst_path = os.path.join(ios_dir, filename)
        if dim == 1024 and (img.width, img.height) == (1024, 1024):
            shutil.copyfile(icon_src, dst_path)
            print(f"Copied exact 1024x1024 iOS {dst_path}")
        else:
            resized = img.resize((dim, dim), Image.Resampling.LANCZOS)
            resized.save(dst_path, "PNG")
            print(f"Wrote iOS {dst_path} ({dim}x{dim})")

    # 3. Windows .ico
    # Windows icon sizes: standard Windows multi-res .ico: 256, 128, 64, 48, 32, 24, 16
    ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (24, 24), (16, 16)]
    ico_path = os.path.join(base, "windows", "runner", "resources", "app_icon.ico")
    img.save(ico_path, format="ICO", sizes=ico_sizes)
    print(f"Wrote Windows {ico_path} with sizes {ico_sizes}")

if __name__ == "__main__":
    main()
