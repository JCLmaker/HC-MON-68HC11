#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

uint8_t calculate_checksum(const uint8_t *data, size_t len) {
    uint8_t sum = 0;
    for (size_t i = 0; i < len; i++) {
        sum += data[i];
    }
    return 0xFF - sum;
}

int bin_to_s19(const char *input_file, const char *output_file, uint32_t start_address) {
    FILE *in_fp = fopen(input_file, "rb");
    if (!in_fp) {
        fprintf(stderr, "Error: Cannot open input file '%s'\n", input_file);
        return 1;
    }

    FILE *out_fp = fopen(output_file, "w");
    if (!out_fp) {
        fclose(in_fp);
        fprintf(stderr, "Error: Cannot open output file '%s'\n", output_file);
        return 1;
    }

    // Optional S0 header
    const char *header_str = "MyBinaryFile";
    size_t header_len = strlen(header_str);
    uint8_t header_count = header_len + 3; // Count + 2-byte address + checksum
    uint16_t header_addr = 0x0000;
    uint8_t header_data[header_len + 3]; // Count + addr (2) + data
    header_data[0] = header_count;
    header_data[1] = (header_addr >> 8) & 0xFF;
    header_data[2] = header_addr & 0xFF;
    memcpy(&header_data[3], header_str, header_len);
    uint8_t header_checksum = calculate_checksum(header_data, header_count - 1); // Exclude checksum itself
    fprintf(out_fp, "S0%02X%04X%s%02X\n", header_count, header_addr, header_str, header_checksum);

    // Data records (S3 for 32-bit address)
    const size_t chunk_size = 32;
    uint8_t chunk[chunk_size];
    size_t offset = 0;
    size_t bytes_read;

    while ((bytes_read = fread(chunk, 1, chunk_size, in_fp)) > 0) {
        uint32_t addr = start_address + offset;
        uint8_t count = bytes_read + 5; // Count + 4-byte addr + checksum
        uint8_t addr_bytes[4] = {
            (addr >> 24) & 0xFF,
            (addr >> 16) & 0xFF,
            (addr >> 8) & 0xFF,
            addr & 0xFF
        };
        uint8_t data[count - 1]; // All except checksum
        data[0] = count;
        memcpy(&data[1], addr_bytes, 4);
        memcpy(&data[5], chunk, bytes_read);
        uint8_t checksum = calculate_checksum(data, count - 1);

        fprintf(out_fp, "S3%02X%08X", count, addr);
        for (size_t i = 0; i < bytes_read; i++) {
            fprintf(out_fp, "%02X", chunk[i]);
        }
        fprintf(out_fp, "%02X\n", checksum);

        offset += bytes_read;
    }

    // S7 termination record
    uint32_t term_addr = 0x00000000;
    uint8_t term_count = 0x05; // Count + 4-byte addr + checksum
    uint8_t term_addr_bytes[4] = {
        (term_addr >> 24) & 0xFF,
        (term_addr >> 16) & 0xFF,
        (term_addr >> 8) & 0xFF,
        term_addr & 0xFF
    };
    uint8_t term_data[5]; // Count + addr (4)
    term_data[0] = term_count;
    memcpy(&term_data[1], term_addr_bytes, 4);
    uint8_t term_checksum = calculate_checksum(term_data, term_count - 1);
    fprintf(out_fp, "S7%02X%08X%02X\n", term_count, term_addr, term_checksum);

    fclose(in_fp);
    fclose(out_fp);
    printf("Conversion complete: '%s' -> '%s'\n", input_file, output_file);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <input.bin> <output.s19> <start_address_hex>\n", argv[0]);
        fprintf(stderr, "Example: %s firmware.bin firmware.s19 0x00000000\n", argv[0]);
        return 1;
    }

    const char *input_file = argv[1];
    const char *output_file = argv[2];
    uint32_t start_address;
    if (sscanf(argv[3], "%x", &start_address) != 1) {
        fprintf(stderr, "Error: Start address must be a valid hexadecimal number (e.g., 0x1000).\n");
        return 1;
    }

    return bin_to_s19(input_file, output_file, start_address);
}