/*****************************************************************************
 * Centrale DCC sur FPGA - construction des trames DCC (NMRA S-9.2)
 *****************************************************************************/

#include "dcc_frame.h"

uint8_t dcc_speed_command(int direction, uint8_t step)
{
    uint8_t cmd = 0x40;              /* 01 D C SSSS, D = 0 par defaut        */
    uint8_t cssss = 0;               /* step 0 = arret : C = 0, SSSS = 0000  */

    if (direction)
        cmd |= 0x20;                 /* D = 1 : marche avant                 */

    if (step > DCC_STEP_MAX)
        step = DCC_STEP_MAX;

    if (step > 0) {
        uint8_t v = step + 3;        /* step 1 -> 4 (00100), step 28 -> 31   */
        cssss = (uint8_t)(((v & 0x01) << 4) | (v >> 1));
    }

    return cmd | cssss;
}

void dcc_build_frame(uint8_t addr, uint8_t cmd1, uint8_t cmd2, int two_bytes,
                     uint32_t *low, uint32_t *high)
{
    uint64_t trame;
    uint8_t ctrl;

    if (two_bytes) {
        ctrl  = addr ^ cmd1 ^ cmd2;
        trame = 0x3FFF;                         /* 14 bits de preambule */
        trame = (trame << 1) | 0;               /* start bit            */
        trame = (trame << 8) | addr;
        trame = (trame << 1) | 0;
        trame = (trame << 8) | cmd1;
        trame = (trame << 1) | 0;
        trame = (trame << 8) | cmd2;
        trame = (trame << 1) | 0;
        trame = (trame << 8) | ctrl;
        trame = (trame << 1) | 1;               /* stop bit             */
    } else {
        ctrl  = addr ^ cmd1;
        trame = 0x7FFFFF;                       /* 23 bits de preambule */
        trame = (trame << 1) | 0;
        trame = (trame << 8) | addr;
        trame = (trame << 1) | 0;
        trame = (trame << 8) | cmd1;
        trame = (trame << 1) | 0;
        trame = (trame << 8) | ctrl;
        trame = (trame << 1) | 1;
    }

    *low  = (uint32_t)(trame & 0xFFFFFFFFu);
    *high = (uint32_t)((trame >> 32) & 0x0007FFFFu);
}
