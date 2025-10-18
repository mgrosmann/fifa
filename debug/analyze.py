#!/usr/bin/env python3
# analyze_txt.py
# Usage: python analyze_txt.py path/to/file.txt

import sys, os, csv

def detect_bom_and_enc(data):
    # data: bytes
    if data.startswith(b'\xff\xfe') or data.startswith(b'\xfe\xff'):
        return 'utf-16'
    if data.startswith(b'\xef\xbb\xbf'):
        return 'utf-8-sig'
    return None

def try_decode(data, enc):
    try:
        s = data.decode(enc)
        return s
    except Exception:
        return None

def detect_encoding(path):
    with open(path, 'rb') as f:
        raw = f.read(4000)
    bom = detect_bom_and_enc(raw)
    if bom:
        return bom
    # try chardet if present
    try:
        import chardet
        info = chardet.detect(raw)
        if info and info.get('encoding'):
            return info['encoding']
    except Exception:
        pass
    # fallback heuristics
    candidates = ['utf-8', 'cp1252', 'latin1', 'utf-16']
    for c in candidates:
        if try_decode(raw, c) is not None:
            return c
    return 'latin1'  # guaranteed decode

def detect_separator(first_line):
    # check common separators; prefer tab if present
    if '\t' in first_line:
        return '\t'
    for sep in [';', ',', '|']:
        if sep in first_line:
            return sep
    # fallback: split on whitespace if many spaces
    if ' ' in first_line:
        return ' '
    return None

def show_raw_hex(path, n=64):
    try:
        import binascii
        with open(path, 'rb') as f:
            b = f.read(n)
        print("Hex head:", binascii.hexlify(b[:32]))
    except Exception:
        pass

def analyze(path):
    if not os.path.exists(path):
        print("ERROR: file not found:", path); return 1

    print("File:", path)
    show_raw_hex(path)

    enc = detect_encoding(path)
    print("Detected encoding (best guess):", enc)

    # open and read the first few lines
    try:
        with open(path, 'r', encoding=enc, errors='replace') as f:
            first_lines = [next(f) for _ in range(5)]
    except StopIteration:
        # file shorter than 5 lines
        with open(path, 'r', encoding=enc, errors='replace') as f:
            first_lines = f.readlines()
    except Exception as e:
        print("Could not read file with encoding", enc, ":", e)
        return 1

    print("\n--- Raw first lines (showing escapes) ---")
    for i, L in enumerate(first_lines, 1):
        print(f"{i:2}: {repr(L.rstrip())}")

    first_line = first_lines[0] if first_lines else ""
    sep = detect_separator(first_line)
    print("\nGuessed field separator:", repr(sep))

    # try parse with csv.reader and count fields per line
    if sep is None:
        sep = '\t'  # try tab as default for DB Master files

    print("\nAttempting to parse and count columns using separator:", repr(sep))
    counts = {}
    sample_rows = []
    total_lines = 0
    bad_lines = []

    try:
        with open(path, 'r', encoding=enc, errors='replace', newline='') as f:
            reader = csv.reader(f, delimiter=sep, quotechar='"')
            for idx, row in enumerate(reader, 1):
                total_lines += 1
                nf = len(row)
                counts[nf] = counts.get(nf, 0) + 1
                if idx <= 5:
                    sample_rows.append(row)
                # record lines that have a different number of fields than the most common so far
                if idx == 10000:
                    break
    except Exception as e:
        print("CSV parse failure:", e)
        return 1

    print("\nTotal lines parsed (sampled up to 10k):", total_lines)
    print("Field-count distribution (field_count: occurrences):")
    for k in sorted(counts.keys()):
        print(f"  {k:3} : {counts[k]}")

    if len(counts) > 1:
        print("\n⚠️  Warning: multiple field counts detected — some lines have different numbers of columns.")
        # try to show first lines with odd counts:
        with open(path, 'r', encoding=enc, errors='replace', newline='') as f:
            reader = csv.reader(f, delimiter=sep, quotechar='"')
            for idx, row in enumerate(reader, 1):
                if len(row) not in (max(counts, key=counts.get),):
                    print(f"Line {idx} has {len(row)} fields — preview: {row[:8]}")
                    break

    print("\n--- Sample parsed rows (first 5) ---")
    for r in sample_rows:
        print(r[:12])  # print first 12 fields

    print("\nAdvice:")
    print("- If the separator is wrong, try rerunning with a different separator (tab, ';', ',').")
    print("- If encoding is utf-16, re-run with encoding='utf-16' and re-save as utf-8 (no null bytes).")
    print("- If multiple field counts appear, some rows include the separator inside quotes or contain embedded CR/LF.")
    return 0

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python analyze_txt.py path/to/file.txt")
        sys.exit(1)
    sys.exit(analyze(sys.argv[1]))

