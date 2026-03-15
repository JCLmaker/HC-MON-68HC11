#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

static uint8_t srec_checksum(const uint8_t *bytes, size_t count_minus_checksum) {
    uint_fast16_t sum = 0;
    for (size_t i = 0; i < count_minus_checksum; i++) {
        sum += bytes[i];
    }
    return (uint8_t)(0xFF - (sum & 0xFF));
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr,
            "Verwendung:\n  %s  eingabe.bin  ausgabe.s19  0x8000\n"
            "  %s  firmware.bin output.s19 49152\n\n"
            "Startadresse: hex (0x...), dezimal oder 0b...\n",
            argv[0], argv[0]);
        return 1;
    }

    const char *input_path  = argv[1];
    const char *output_path = argv[2];
    const char *addr_str    = argv[3];

    char *endptr;
    uint32_t start_addr = (uint32_t)strtoul(addr_str, &endptr, 0);
    if (endptr == addr_str || *endptr != '\0') {
        fprintf(stderr, "Fehler: Ungültige Startadresse: '%s'\n", addr_str);
        return 1;
    }

    if (start_addr > 0xFFFF) {
        fprintf(stderr, "Warnung: Adresse > 0xFFFF → maskiert auf 16 Bit\n");
        start_addr &= 0xFFFF;
    }

    FILE *fin = fopen(input_path, "rb");
    if (!fin) {
        fprintf(stderr, "Kann Eingabe nicht öffnen: %s\n", input_path);
        return 1;
    }

    FILE *fout = fopen(output_path, "w");
    if (!fout) {
        fclose(fin);
        fprintf(stderr, "Kann Ausgabe nicht erstellen: %s\n", output_path);
        return 1;
    }

    // Dateigröße
    fseek(fin, 0, SEEK_END);
    long total_bytes = ftell(fin);
    fseek(fin, 0, SEEK_SET);

    // ─── S0 Header ────────────────────────────────────────
    const char *header_text = "Converted binary";
    size_t hdr_len = strlen(header_text);
    uint8_t count = (uint8_t)(hdr_len + 3);   // Byte-Count = Adresse(2) + Daten + Checksum

    uint8_t line[3 + 64];   // genug Platz
    line[0] = count;
    line[1] = 0x00;         // Adresse high
    line[2] = 0x00;         // Adresse low

    memcpy(&line[3], header_text, hdr_len);

    uint8_t chksum = srec_checksum(line, count);   // ← Alle Bytes bis vor Checksum!
    // count enthält bereits die Checksum-Position → summe über count Bytes (exkl. checksum)

    fprintf(fout, "S0%02X%04X%s%02X\n",
            count, 0x0000u, header_text, chksum);

    // ─── S1 Datenzeilen ───────────────────────────────────
    #define MAX_DATA 32
    uint8_t buffer[MAX_DATA];
    uint32_t offset = 0;
    size_t n;

    while ((n = fread(buffer, 1, MAX_DATA, fin)) > 0) {
        uint16_t addr = (uint16_t)(start_addr + offset);
        uint8_t cnt = (uint8_t)(n + 3);           // count = addr(2) + daten + checksum

        line[0] = cnt;
        line[1] = (uint8_t)(addr >> 8);
        line[2] = (uint8_t) addr;
        memcpy(&line[3], buffer, n);

        uint8_t chk = srec_checksum(line, cnt);   // ← korrigierte Übergabe!

        fprintf(fout, "S1%02X%04X", cnt, addr);
        for (size_t i = 0; i < n; i++) {
            fprintf(fout, "%02X", buffer[i]);
        }
        fprintf(fout, "%02X\n", chk);

        offset += n;
    }

    // ─── S9 Termination ───────────────────────────────────
    uint16_t exec_addr = (uint16_t)start_addr;
    uint8_t cnt_term = 3;

    line[0] = cnt_term;
    line[1] = (uint8_t)(exec_addr >> 8);
    line[2] = (uint8_t) exec_addr;

    uint8_t chk_term = srec_checksum(line, cnt_term);

    fprintf(fout, "S9%02X%04X%02X\n", cnt_term, exec_addr, chk_term);

    fclose(fin);
    fclose(fout);

    printf("Fertig: %s erstellt\n", output_path);
    printf("  Start : 0x%04X\n", (uint16_t)start_addr);
    printf("  Bytes : %ld\n", total_bytes);

    return 0;
}