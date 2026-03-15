#!/usr/bin/env python3

import sys
import os

def calculate_checksum(data_bytes):
    """
    Calculate the S-Record checksum: one's complement of the sum of bytes.
    """
    total = sum(data_bytes)
    return 0xFF - (total & 0xFF)

def bin_to_s19(input_file, output_file, start_address):
    """
    Convert a binary file to Motorola S19 format.
    Assumes 32-bit addressing (S3 records).
    """
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' does not exist.")
        sys.exit(1)

    with open(input_file, 'rb') as f:
        binary_data = f.read()

    with open(output_file, 'w') as f:
        # Optional S0 header (you can customize or remove)
        header = b'MyBinaryFile'  # Example header data
        header_count = len(header) + 3  # Count + 2-byte address + checksum
        header_addr = 0x0000
        header_bytes = [header_count] + [(header_addr >> 8) & 0xFF, header_addr & 0xFF] + list(header)
        header_checksum = calculate_checksum(header_bytes)
        f.write(f"S0{header_count:02X}{header_addr:04X}{header.hex().upper()}{header_checksum:02X}\n")

        # Data records (S3)
        chunk_size = 32  # Bytes per data line, adjustable
        offset = 0
        while offset < len(binary_data):
            chunk = binary_data[offset:offset + chunk_size]
            if not chunk:
                break
            addr = start_address + offset
            count = len(chunk) + 5  # Count + 4-byte address + checksum
            addr_bytes = [
                (addr >> 24) & 0xFF,
                (addr >> 16) & 0xFF,
                (addr >> 8) & 0xFF,
                addr & 0xFF
            ]
            data_bytes = [count] + addr_bytes + list(chunk)
            checksum = calculate_checksum(data_bytes)
            data_hex = ''.join(f"{b:02X}" for b in chunk)
            f.write(f"S3{count:02X}{addr:08X}{data_hex}{checksum:02X}\n")
            offset += len(chunk)

        # S7 termination record (execution start address 0x00000000)
        term_count = 0x05  # Count + 4-byte address + checksum
        term_addr = 0x00000000
        term_addr_bytes = [
            (term_addr >> 24) & 0xFF,
            (term_addr >> 16) & 0xFF,
            (term_addr >> 8) & 0xFF,
            term_addr & 0xFF
        ]
        term_bytes = [term_count] + term_addr_bytes
        term_checksum = calculate_checksum(term_bytes)
        f.write(f"S7{term_count:02X}{term_addr:08X}{term_checksum:02X}\n")

    print(f"Conversion complete: '{input_file}' -> '{output_file}'")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 bin_to_s19.py <input.bin> <output.s19> <start_address_hex>")
        print("Example: python3 bin_to_s19.py firmware.bin firmware.s19 0x00000000")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    try:
        start_address = int(sys.argv[3], 16)
    except ValueError:
        print("Error: Start address must be a valid hexadecimal number (e.g., 0x1000).")
        sys.exit(1)

    bin_to_s19(input_file, output_file, start_address)

