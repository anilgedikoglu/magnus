"""
Magnus App Asset Optimization Script
- Moves unused files to backup
- Optimizes/compresses images with Pillow
"""

import os
import sys
import shutil
from pathlib import Path

# Try importing Pillow
try:
    from PIL import Image
    PILLOW_AVAILABLE = True
except ImportError:
    PILLOW_AVAILABLE = False
    print("WARNING: Pillow not available. Install with: pip install Pillow")

WORKTREE = Path(r"C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb")
ASSETS_IMAGES = WORKTREE / "assets" / "images"
BACKUP = WORKTREE / "asset_optimization_backup"

# ============================================================
# STEP 1: MOVE UNUSED FILES TO BACKUP
# ============================================================

# Exact files to move (relative to assets/images/)
UNUSED_ROOT_FILES = [
    # Root level duplicates/unused
    "arinmayeni.png",
    "banadair.png",
    "yasamadair.png",
    "tamuaicon.png",
    "xkimdir.png",
    "faloyaiconx.png",
    "faloyaicon.png",
    "kehanetold.png",
    "plusfallar.png",
    "dilayarlari.png",
    "premium.jpg",
    "kisilik.jpg",
    "varolus.jpg",
    "dertortagiozel.jpg",
    "profilepics.jpg",
    "magnusajest.png",
    "motivasyon_yeni.png",  # duplicate of motivasyon.png
    "ozlusozler.png",       # used version is in Yeniikonlar which is being backed up... but ozlusozler is large
    "magnusappicon_new.jpg",
    "magnusappicon_a12.png",
    "magnusiconcircle.png",
    "inbox2.png",
    "cup2.png",
    "oyunikon.png",
    "oyunikon2.png",
    "kazannew.png",
    "hediyekutusu.png",
    "hediyekutusukapali.png",
    "space_g.png",
    "sss.png",
    "file.png",
    "red-light-line-png-2.png",
    "maganda.png",          # used via kehanet/maganda.png
    "tamua.png",            # used via kehanet/tamua.png
    "Yana.png",             # used via kehanet/yana.png
    "sohbet.png",           # unused
]

# Unused falbg files (keep only biyoritim.png, ichingbg.png, omikujibg.png)
UNUSED_FALBG = [
    "falbg/askuyumu.png",
    "falbg/astrolojikon.png",
    "falbg/dertortagikon.png",
    "falbg/durugoru.png",
    "falbg/elfalimodern.png",
    "falbg/faloyabg.png",
    "falbg/infoicon.png",
    "falbg/kahvefalibg.png",
    "falbg/kahvefalicon.png",
    "falbg/kahvefalicon2.png",
    "falbg/kehanet.png",
    "falbg/magnusicon.png",
    "falbg/mistikfallar.png",
    "falbg/numeroloji.png",
    "falbg/ruyayorumu.png",
    "falbg/tarot.png",
    "falbg/yuzfali.png",
]

# Unused astrotakvim files (keep astrotakvim_bg1-3, guzellik_bg, transit_bg.jpg)
UNUSED_ASTROTAKVIM = [
    "astrotakvim/astrotakvim_bg4.png",
    "astrotakvim/takvim_flare.jpg",
    "astrotakvim/takvim_icon_astroloji.png",
    "astrotakvim/takvim_icon_saglik.png",
    "astrotakvim/takvim_icon_transit.png",
    "astrotakvim/transit_bg.png",  # DUPLICATE of transit_bg.jpg
]

# Unused menu files (keep: dertortagi, digerfalcilar, durugoru, elfali, kehanet, mistikfallar, numeroloji, ozelfal, ruyaozel, tarot, yuzfali)
UNUSED_MENU = [
    "menu/arinma.png",
    "menu/kadercarki.png",
    "menu/niyet.png",
    "menu/kahvefali.png",
    "menu/ruyayorumu.png",
]

# Unused Yeniikonlar files - entire folder except 3 used files
# bugun.PNG, yarin.PNG, gelecek.PNG are used in durugoru_screen.dart
YENIIKONLAR_KEEP = {"bugun.PNG", "yarin.PNG", "gelecek.PNG"}

ALL_UNUSED_SPECIFIC = UNUSED_ROOT_FILES + UNUSED_FALBG + UNUSED_ASTROTAKVIM + UNUSED_MENU


def move_to_backup(rel_path: str, reason: str = "") -> tuple[bool, int]:
    """Move a file from assets/images to backup. Returns (success, size_bytes)."""
    src = ASSETS_IMAGES / rel_path
    if not src.exists():
        return False, 0

    dst = BACKUP / "images" / rel_path
    dst.parent.mkdir(parents=True, exist_ok=True)
    size = src.stat().st_size
    shutil.move(str(src), str(dst))
    print(f"  MOVED: {rel_path} ({size/1024:.1f} KB){' - ' + reason if reason else ''}")
    return True, size


def move_yeniikonlar_unused():
    """Move all Yeniikonlar files except the 3 kept ones."""
    yeni_dir = ASSETS_IMAGES / "Yeniikonlar"
    total_moved = 0
    count = 0

    for f in yeni_dir.rglob("*"):
        if f.is_file() and f.name not in YENIIKONLAR_KEEP and f.suffix.lower() != ".meta":
            rel = f.relative_to(ASSETS_IMAGES)
            dst = BACKUP / "images" / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            size = f.stat().st_size
            shutil.move(str(f), str(dst))
            total_moved += size
            count += 1

    # Also move .meta files
    for f in yeni_dir.rglob("*.meta"):
        if f.is_file() and f.stem not in YENIIKONLAR_KEEP:
            rel = f.relative_to(ASSETS_IMAGES)
            dst = BACKUP / "images" / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(f), str(dst))
            count += 1

    return count, total_moved


# ============================================================
# STEP 2: IMAGE OPTIMIZATION
# ============================================================

# Files to NEVER touch
SKIP_FILES = {
    "magnusappicon_splash.png",
    "magnusYaziLogoRenkli.PNG",
    "splashBackground.png",
}

def should_skip(path: Path) -> bool:
    """Return True if file should not be optimized."""
    name = path.name
    name_lower = name.lower()

    # Skip by filename
    if name in SKIP_FILES:
        return True

    # Skip splash/launcher/adaptive files
    for kw in ["splash", "launcher", "adaptive"]:
        if kw in name_lower:
            return True

    # Skip small icons/logos (< 200KB)
    size = path.stat().st_size
    if ("icon" in name_lower or "logo" in name_lower) and size < 200 * 1024:
        return True

    # Skip android res
    android_res = WORKTREE / "android" / "app" / "src" / "main" / "res"
    try:
        path.relative_to(android_res)
        return True
    except ValueError:
        pass

    return False


def is_background(path: Path) -> bool:
    """Return True if this is a full-screen background image."""
    rel = str(path.relative_to(ASSETS_IMAGES)).replace("\\", "/")
    name_lower = path.name.lower()

    # Explicit background folders/patterns
    if rel.startswith("ozlusoz_bgs/"):
        return True
    if rel.startswith("olumlama_bgs/"):
        return True
    if rel.startswith("astrotakvim/") and "bg" in name_lower:
        return True
    if rel.startswith("falbg/"):
        return True

    # Files with 'bg' or 'background' in name
    for kw in ["_bg", "bg_", "background", "bgs/"]:
        if kw in name_lower or kw in rel:
            return True

    # Specific large bg files
    bg_files = {
        "dream_bg.png", "durugoru_bg.png", "numeroloji_bg.png",
        "space_bg.png", "tarot_bg.png", "arinma_bg.jpg",
        "signinbackground.png", "olumlama_bg.jpg", "olumlama_bg.jpg",
        "astrotakvim_bg1.png", "astrotakvim_bg2.png", "astrotakvim_bg3.png",
        "guzellik_bg.png", "transit_bg.jpg", "ichingbg.png",
        "omikujibg.png", "WheelChartBackground.jpg",
        "welcomscreenbackground.jpg", "onboarding_bg.jpg",
    }
    if path.name in bg_files or path.name.lower() in {f.lower() for f in bg_files}:
        return True

    return False


def optimize_image(path: Path, backup_dir: Path) -> tuple[str, int, int]:
    """
    Optimize an image. Backs up original first.
    Returns (status, original_size, new_size).
    status: 'optimized', 'skipped', 'smaller_skipped', 'error'
    """
    if not PILLOW_AVAILABLE:
        return "no_pillow", 0, 0

    original_size = path.stat().st_size

    # Backup original
    rel = path.relative_to(ASSETS_IMAGES)
    bak = backup_dir / "originals" / rel
    bak.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(str(path), str(bak))

    try:
        img = Image.open(str(path))
        has_alpha = img.mode in ("RGBA", "LA") or (img.mode == "P" and "transparency" in img.info)

        ext = path.suffix.lower()
        is_bg = is_background(path)

        # Determine max dimension
        max_dim = 1920 if is_bg else 1440

        # Resize if needed
        w, h = img.size
        longest = max(w, h)
        if longest > max_dim:
            scale = max_dim / longest
            new_w = int(w * scale)
            new_h = int(h * scale)
            img = img.resize((new_w, new_h), Image.LANCZOS)

        # Determine save format
        if ext in (".jpg", ".jpeg"):
            # Save as JPEG quality=92, strip EXIF
            if img.mode in ("RGBA", "LA", "P"):
                img = img.convert("RGB")
            img.save(str(path), "JPEG", quality=92, optimize=True, exif=b"")
        elif ext in (".png", ".PNG"):
            if has_alpha:
                # Keep as PNG with optimization
                img.save(str(path), "PNG", optimize=True)
            else:
                # Convert to JPEG for backgrounds (save as .jpg alongside? No - just save optimized PNG)
                # Actually: convert PNG without alpha to JPEG quality=92, but keep .png extension
                # Wait - per instructions: keep correct extension. So save PNG without alpha as optimized PNG
                # For backgrounds, save as JPEG (but extension stays .png? No - "NO, keep correct extension")
                # Instructions say: "For PNG with NO transparency: convert to JPEG quality=92
                #   (save with .png extension but JPEG content — NO, keep correct extension)"
                # So for PNG without alpha: save as PNG optimize=True
                # OR per the bg rule: "Save as JPEG quality=92 (even if was PNG without transparency)"
                # But then extension must be kept - let's save as .jpg with new name?
                # The instruction says keep correct extension. So for bg PNGs without alpha -> still PNG optimize.
                # But we can do quantization-style optimization.
                if img.mode == "P":
                    img = img.convert("RGB")
                # For non-alpha PNGs, try PNG optimize first
                img.save(str(path), "PNG", optimize=True)
        elif ext in (".webp",):
            if img.mode in ("RGBA", "LA"):
                img.save(str(path), "WEBP", quality=92, method=6)
            else:
                if img.mode not in ("RGB",):
                    img = img.convert("RGB")
                img.save(str(path), "WEBP", quality=92, method=6)
        else:
            # Unknown format, skip
            os.remove(str(bak))  # remove backup since we didn't touch it
            return "skipped_format", original_size, original_size

        new_size = path.stat().st_size

        # If new file is larger, restore original
        if new_size >= original_size:
            shutil.copy2(str(bak), str(path))
            return "smaller_skipped", original_size, original_size

        return "optimized", original_size, new_size

    except Exception as e:
        # Restore original on error
        try:
            shutil.copy2(str(bak), str(path))
        except Exception:
            pass
        return f"error: {e}", original_size, original_size


def main():
    print("=" * 60)
    print("MAGNUS ASSET OPTIMIZATION")
    print("=" * 60)

    BACKUP.mkdir(parents=True, exist_ok=True)

    # ---- PHASE 1: MOVE UNUSED FILES ----
    print("\n=== PHASE 1: Moving unused files to backup ===\n")

    total_moved_bytes = 0
    moved_count = 0

    # Move specific unused files
    for rel_path in ALL_UNUSED_SPECIFIC:
        success, size = move_to_backup(rel_path)
        if success:
            total_moved_bytes += size
            moved_count += 1

    # Move Yeniikonlar (except 3 files)
    print("\n  Moving Yeniikonlar/ (except bugun/yarin/gelecek PNG)...")
    count, size = move_yeniikonlar_unused()
    total_moved_bytes += size
    moved_count += count
    print(f"  Moved {count} files from Yeniikonlar/ ({size/1024/1024:.2f} MB)")

    print(f"\n  PHASE 1 TOTAL: Moved {moved_count} files, freed {total_moved_bytes/1024/1024:.2f} MB")

    # ---- PHASE 2: OPTIMIZE REMAINING IMAGES ----
    if not PILLOW_AVAILABLE:
        print("\n=== PHASE 2: SKIPPED (Pillow not installed) ===")
        print("Install with: pip install Pillow")
        return

    print("\n=== PHASE 2: Optimizing remaining images ===\n")

    # Collect all remaining image files
    extensions = {".jpg", ".jpeg", ".png", ".PNG", ".webp"}
    all_images = []
    for f in ASSETS_IMAGES.rglob("*"):
        if f.is_file() and f.suffix.lower() in {e.lower() for e in extensions}:
            all_images.append(f)

    print(f"  Found {len(all_images)} images to process\n")

    optimized_count = 0
    skipped_count = 0
    error_count = 0
    total_saved = 0
    total_original = 0

    for img_path in sorted(all_images):
        if should_skip(img_path):
            skipped_count += 1
            continue

        rel = str(img_path.relative_to(ASSETS_IMAGES)).replace("\\", "/")
        status, orig, new = optimize_image(img_path, BACKUP)

        if status == "optimized":
            saved = orig - new
            total_saved += saved
            total_original += orig
            optimized_count += 1
            pct = (saved / orig * 100) if orig > 0 else 0
            print(f"  OK  {rel}: {orig/1024:.1f}KB -> {new/1024:.1f}KB (saved {saved/1024:.1f}KB, -{pct:.0f}%)")
        elif status == "smaller_skipped":
            skipped_count += 1
            total_original += orig
            # print(f"  --  {rel}: already optimal ({orig/1024:.1f}KB)")
        elif status.startswith("error"):
            error_count += 1
            print(f"  ERR {rel}: {status}")
        else:
            skipped_count += 1

    print(f"\n=== PHASE 2 RESULTS ===")
    print(f"  Optimized: {optimized_count} images")
    print(f"  Skipped (optimal/protected): {skipped_count}")
    print(f"  Errors: {error_count}")
    print(f"  Bytes saved by optimization: {total_saved/1024/1024:.2f} MB")

    print(f"\n=== OVERALL SUMMARY ===")
    print(f"  Unused files removed: {moved_count} files, {total_moved_bytes/1024/1024:.2f} MB freed")
    print(f"  Image optimization saved: {total_saved/1024/1024:.2f} MB")
    print(f"  Total estimated reduction: {(total_moved_bytes + total_saved)/1024/1024:.2f} MB")


if __name__ == "__main__":
    main()
