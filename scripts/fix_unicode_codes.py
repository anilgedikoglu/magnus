"""
Scans all .json files in assets/data/ for U0001XXXX and U0000XXXX style codes
and replaces them with actual Unicode characters.
"""

import os
import re
import sys

DATA_DIR = r'C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb\assets\data'


def decode_unicode_codes(text):
    """
    Replace U0001XXXX and U0000XXXX patterns with actual Unicode characters.
    Returns (new_text, count_of_replacements, list_of_samples)
    """
    replacements = 0
    samples = []

    # We'll do two passes: U0001XXXX first, then U0000XXXX
    # Pattern: U0001 followed by exactly 4 hex digits
    # Pattern: U0000 followed by exactly 4 hex digits
    # We search character by character to avoid regex \u issues

    result = []
    i = 0
    n = len(text)

    while i < n:
        # Check for U0001 pattern
        if (i + 9 <= n and
                text[i] == 'U' and
                text[i+1] == '0' and
                text[i+2] == '0' and
                text[i+3] == '0' and
                text[i+4] == '1'):
            # Check next 4 chars are hex digits
            hex_part = text[i+5:i+9]
            if len(hex_part) == 4 and all(c in '0123456789ABCDEFabcdef' for c in hex_part):
                # Convert: chr(int('1' + hex_part, 16))
                code_point = int('1' + hex_part, 16)
                try:
                    char = chr(code_point)
                    original = text[i:i+9]
                    if len(samples) < 10:
                        samples.append(f"  {original!r} -> {char!r} (U+{code_point:X})")
                    result.append(char)
                    replacements += 1
                    i += 9
                    continue
                except (ValueError, OverflowError):
                    pass

        # Check for U0000 pattern
        if (i + 9 <= n and
                text[i] == 'U' and
                text[i+1] == '0' and
                text[i+2] == '0' and
                text[i+3] == '0' and
                text[i+4] == '0'):
            # Check next 4 chars are hex digits
            hex_part = text[i+5:i+9]
            if len(hex_part) == 4 and all(c in '0123456789ABCDEFabcdef' for c in hex_part):
                code_point = int(hex_part, 16)
                if code_point > 0:  # Skip null char
                    try:
                        char = chr(code_point)
                        original = text[i:i+9]
                        if len(samples) < 10:
                            samples.append(f"  {original!r} -> {char!r} (U+{code_point:X})")
                        result.append(char)
                        replacements += 1
                        i += 9
                        continue
                    except (ValueError, OverflowError):
                        pass

        result.append(text[i])
        i += 1

    return ''.join(result), replacements, samples


def check_suspicious_patterns(text, filename):
    """Check for other suspicious patterns."""
    suspicious = []

    # Check for \xXX literal sequences (not actual escape, but the 4-char string)
    i = 0
    n = len(text)
    while i < n:
        if (i + 3 < n and
                text[i] == '\\' and
                text[i+1] == 'x' and
                all(c in '0123456789ABCDEFabcdef' for c in text[i+2:i+4])):
            suspicious.append(f"  \\x escape at pos {i}: {text[max(0,i-10):i+10]!r}")
            i += 4
            continue

        # Check for \uXXXX literal (as 6-char string backslash+u+4hex)
        if (i + 5 < n and
                text[i] == '\\' and
                text[i+1] == 'u' and
                all(c in '0123456789ABCDEFabcdef' for c in text[i+2:i+6])):
            suspicious.append(f"  \\u escape at pos {i}: {text[max(0,i-10):i+10]!r}")
            i += 6
            continue

        i += 1

    return suspicious[:5]  # Return at most 5 examples


def main():
    if not os.path.isdir(DATA_DIR):
        print(f"ERROR: Directory not found: {DATA_DIR}")
        sys.exit(1)

    json_files = [f for f in os.listdir(DATA_DIR) if f.endswith('.json')]
    json_files.sort()

    print(f"Scanning {len(json_files)} JSON files in:\n  {DATA_DIR}\n")
    print("=" * 70)

    total_replacements = 0
    files_fixed = []
    files_with_suspicious = []

    for fname in json_files:
        fpath = os.path.join(DATA_DIR, fname)

        try:
            with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
                original_text = f.read()
        except Exception as e:
            print(f"ERROR reading {fname}: {e}")
            continue

        new_text, count, samples = decode_unicode_codes(original_text)
        suspicious = check_suspicious_patterns(new_text, fname)

        if count > 0:
            # Write fixed content back
            try:
                with open(fpath, 'w', encoding='utf-8') as f:
                    f.write(new_text)
                files_fixed.append((fname, count, samples))
                total_replacements += count
                print(f"FIXED: {fname}")
                print(f"  Replacements: {count}")
                for s in samples:
                    print(s)
                print()
            except Exception as e:
                print(f"ERROR writing {fname}: {e}")
        else:
            print(f"  OK: {fname} (no U000XXXXX codes found)")

        if suspicious:
            files_with_suspicious.append((fname, suspicious))

    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Total files scanned: {len(json_files)}")
    print(f"Files fixed: {len(files_fixed)}")
    print(f"Total replacements: {total_replacements}")

    if files_fixed:
        print("\nFixed files:")
        for fname, count, _ in files_fixed:
            print(f"  {fname}: {count} replacements")

    if files_with_suspicious:
        print("\nFiles with OTHER suspicious patterns:")
        for fname, patterns in files_with_suspicious:
            print(f"  {fname}:")
            for p in patterns:
                print(f"    {p}")
    else:
        print("\nNo other suspicious patterns found.")


if __name__ == '__main__':
    main()
