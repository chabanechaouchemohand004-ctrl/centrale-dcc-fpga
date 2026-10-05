/*****************************************************************************
 * Centrale DCC sur FPGA - construction des trames DCC (NMRA S-9.2)
 *
 * Code C portable (aucune dependance Xilinx) : compile aussi bien pour le
 * MicroBlaze que sur PC, ce qui permet de le tester unitairement
 * (voir sw/test/test_dcc_frame.c).
 *****************************************************************************/

#ifndef DCC_FRAME_H
#define DCC_FRAME_H

#include <stdint.h>

#define DCC_STEP_MAX 28

/*
 * Octet vitesse/direction, format NMRA 01DCSSSS.
 *   direction : 1 = marche avant, 0 = marche arriere
 *   step      : 0 = arret, 1..28 = cran de vitesse (sature a 28)
 * Le bit C est le bit de poids FAIBLE de la vitesse (NMRA S-9.2), d'ou la
 * conversion cran -> CSSSS : v = step + 3, SSSS = v >> 1, C = v & 1.
 */
uint8_t dcc_speed_command(int direction, uint8_t step);

/*
 * Construit la trame complete de 51 bits et la decoupe pour les registres AXI :
 *   *low  <- bits 31..0   (REG0)
 *   *high <- bits 50..32  (REG1, 19 bits utiles)
 *
 * Format 1 octet  (two_bytes = 0) : [23 x 1] 0 [addr] 0 [cmd1] 0 [ctrl] 1
 * Format 2 octets (two_bytes = 1) : [14 x 1] 0 [addr] 0 [cmd1] 0 [cmd2] 0 [ctrl] 1
 * ctrl = XOR de tous les octets precedents.
 */
void dcc_build_frame(uint8_t addr, uint8_t cmd1, uint8_t cmd2, int two_bytes,
                     uint32_t *low, uint32_t *high);

#endif
