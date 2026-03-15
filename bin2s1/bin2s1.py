#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os

def calculate_srec_checksum(byte_list):
    """ Berechnet den S-Record Checksum: 0xFF - (Summe aller Bytes modulo 256) """
    total = sum(byte_list) & 0xFF
    return 0xFF - total

def bin_to_s19_s1(input_path, output_path, start_address):
    """
    Wandelt eine Binärdatei in Motorola S-Record Format mit S1-Records um
    (16-Bit Adressen – max. 64 kB pro zusammenhängendem Block)
    """
    if not os.path.isfile(input_path):
        print(f"Fehler: Datei '{input_path}' nicht gefunden.", file=sys.stderr)
        return False

    try:
        start_addr = int(start_address, 0)  # unterstützt 0x, 0b, dezimal
    except ValueError:
        print("Fehler: Startadresse ungültig (Beispiel: 0x8000 oder 32768)", file=sys.stderr)
        return False

    if start_addr > 0xFFFF:
        print("Warnung: Adresse > 0xFFFF → wird auf 16 Bit abgeschnitten!", file=sys.stderr)
        start_addr &= 0xFFFF

    with open(input_path, "rb") as f:
        data = f.read()

    if not data:
        print("Warnung: Eingabedatei ist leer.", file=sys.stderr)

    with open(output_path, "w", encoding="ascii") as out:
        # ────────────── S0 Header (optional) ──────────────
        header_text = "Converted binary"
        header_bytes = list(header_text.encode("ascii"))
        count = len(header_bytes) + 3  # count + addr(2) + checksum
        addr = 0x0000
        line = [count, (addr >> 8) & 0xFF, addr & 0xFF] + header_bytes
        checksum = calculate_srec_checksum(line)
        out.write(f"S0{count:02X}{addr:04X}{header_text}{checksum:02X}\n")

        # ────────────── S1 Datenzeilen ──────────────
        MAX_DATA_PER_LINE = 32
        offset = 0

        while offset < len(data):
            chunk_size = min(MAX_DATA_PER_LINE, len(data) - offset)
            chunk = data[offset : offset + chunk_size]

            addr = (start_addr + offset) & 0xFFFF
            count = chunk_size + 3  # count + addr(2) + checksum

            line_bytes = [count, (addr >> 8) & 0xFF, addr & 0xFF]
            line_bytes.extend(chunk)

            checksum = calculate_srec_checksum(line_bytes)

            out.write(f"S1{count:02X}{addr:04X}")
            for b in chunk:
                out.write(f"{b:02X}")
            out.write(f"{checksum:02X}\n")

            offset += chunk_size

        # ────────────── S9 End Record ──────────────
        count = 3  # count + start addr(2) + checksum
        exec_addr = start_addr & 0xFFFF
        line = [count, (exec_addr >> 8) & 0xFF, exec_addr & 0xFF]
        checksum = calculate_srec_checksum(line)
        out.write(f"S9{count:02X}{exec_addr:04X}{checksum:02X}\n")

    print(f"Erzeugt: {output_path}")
    print(f"  Startadresse: 0x{start_addr:04X}")
    print(f"  Bytes: {len(data):,} → {offset:,} in S1-Records geschrieben")
    return True


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Verwendung:")
        print("  python3 bin2s1.py  eingabe.bin  ausgabe.s19  0x8000")
        print("  python3 bin2s1.py  firmware.bin output.s19 32768")
        sys.exit(1)

    input_file  = sys.argv[1]
    output_file = sys.argv[2]
    start_addr  = sys.argv[3]

    success = bin_to_s19_s1(input_file, output_file, start_addr)

    sys.exit(0 if success else 1)