/*****************************************************************************
 * Tests unitaires sur PC de sw/dcc_frame.c (sans carte, sans Vitis).
 *
 *   gcc -Wall -Wextra -I.. test_dcc_frame.c ../dcc_frame.c -o test && ./test
 *
 * Les trames de reference sont celles du generateur VHDL de la Phase 1
 * (rtl/phase1/Generateur_Trames.vhd), validees sur la maquette : le code C
 * de la Phase 2 doit produire exactement les memes 51 bits.
 *****************************************************************************/

#include <stdio.h>
#include <stdint.h>
#include "dcc_frame.h"

static int nb_tests = 0, nb_echecs = 0;

static void check_u8(const char *nom, uint8_t obtenu, uint8_t attendu)
{
    nb_tests++;
    if (obtenu != attendu) {
        nb_echecs++;
        printf("ECHEC %-34s obtenu 0x%02X, attendu 0x%02X\n", nom, obtenu, attendu);
    }
}

static void check_trame(const char *nom, uint8_t cmd1, uint8_t cmd2,
                        int two_bytes, uint64_t attendu)
{
    uint32_t low, high;
    uint64_t obtenu;

    dcc_build_frame(0x03, cmd1, cmd2, two_bytes, &low, &high);
    obtenu = ((uint64_t)high << 32) | low;

    nb_tests++;
    if (obtenu != attendu) {
        nb_echecs++;
        printf("ECHEC %-34s obtenu 0x%013llX, attendu 0x%013llX\n", nom,
               (unsigned long long)obtenu, (unsigned long long)attendu);
    }
}

int main(void)
{
    /* Octet vitesse/direction 01DCSSSS (table NMRA S-9.2) */
    check_u8("arret, marche avant",        dcc_speed_command(1, 0),  0x60);
    check_u8("arret, marche arriere",      dcc_speed_command(0, 0),  0x40);
    check_u8("avant step 1  (C=0 SSSS=2)", dcc_speed_command(1, 1),  0x62);
    check_u8("avant step 2  (C=1 SSSS=2)", dcc_speed_command(1, 2),  0x72);
    check_u8("avant step 10",              dcc_speed_command(1, 10), 0x76);
    check_u8("arriere step 10",            dcc_speed_command(0, 10), 0x56);
    check_u8("avant step 28 (max)",        dcc_speed_command(1, 28), 0x7F);
    check_u8("saturation step 31 -> 28",   dcc_speed_command(1, 31), 0x7F);

    /* Trames completes, comparees au generateur VHDL de la Phase 1 */
    check_trame("arret (defaut)",       0x60, 0x00, 0, 0x7FFFFF01980C7ULL);
    check_trame("marche avant step 10", 0x76, 0x00, 0, 0x7FFFFF019D8EBULL);
    check_trame("marche arriere step 10", 0x56, 0x00, 0, 0x7FFFFF01958ABULL);
    check_trame("phares ON (F0)",       0x90, 0x00, 0, 0x7FFFFF01A4127ULL);
    check_trame("phares OFF (F0)",      0x80, 0x00, 0, 0x7FFFFF01A0107ULL);
    check_trame("klaxon ON (F11)",      0xA4, 0x00, 0, 0x7FFFFF01A914FULL);
    check_trame("klaxon OFF (F11)",     0xA0, 0x00, 0, 0x7FFFFF01A8147ULL);
    check_trame("annonce F13 ON",       0xDE, 0x01, 1, 0x7FFE036F005B9ULL);
    check_trame("annonce F13 OFF",      0xDE, 0x00, 1, 0x7FFE036F001BBULL);

    /* La marche arriere doit passer par l'API vitesse, pas par une constante */
    check_trame("API: arriere step 10", dcc_speed_command(0, 10), 0x00, 0,
                0x7FFFFF01958ABULL);

    printf("%d/%d tests OK\n", nb_tests - nb_echecs, nb_tests);
    return nb_echecs ? 1 : 0;
}
