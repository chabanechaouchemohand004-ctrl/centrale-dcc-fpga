/*****************************************************************************
 * Centrale DCC sur FPGA - Phase 2 : application MicroBlaze (standalone)
 * Auteur : Mohand CHABANE CHAOUCHE
 *
 * Lit les switches/boutons de la Basys 3, construit la trame DCC
 * correspondante (51 bits, train d'adresse 3) et l'envoie a l'IP
 * Centrale_DCC via le bus AXI-Lite quand l'utilisateur appuie sur BTNU.
 *
 * Mapping des entrees :
 *   SW[7:0]   selection de la commande (SW7 prioritaire, comme en Phase 1)
 *               SW7 marche avant      SW6 marche arriere
 *               SW5 phares ON         SW4 phares OFF
 *               SW3 klaxon ON         SW2 klaxon OFF
 *               SW1 annonce F13 ON    SW0 annonce F13 OFF
 *   SW[12:8]  cran de vitesse 0..28 en binaire (utilise avec SW7/SW6)
 *   BTNU      valide et envoie la trame courante
 *   LED[7:0]  octet de commande courant
 *   LED[15]   bascule a chaque envoi (confirmation visuelle)
 *****************************************************************************/

#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "Centrale_DCC.h"
#include "dcc_frame.h"

#define GPIO_BTN_ID      XPAR_GPIO_BTN_DEVICE_ID
#define GPIO_SW_ID       XPAR_GPIO_SW_DEVICE_ID
#define GPIO_LED_ID      XPAR_GPIO_LED_DEVICE_ID

#define DCC_BASE_ADDR    XPAR_CENTRALE_DCC_0_S00_AXI_BASEADDR
#define DCC_REG0_OFFSET  CENTRALE_DCC_S00_AXI_SLV_REG0_OFFSET  /* bits 31..0  */
#define DCC_REG1_OFFSET  CENTRALE_DCC_S00_AXI_SLV_REG1_OFFSET  /* bits 50..32 */
#define DCC_REG2_OFFSET  CENTRALE_DCC_S00_AXI_SLV_REG2_OFFSET  /* bit 0 = validation */

#define TRAIN_ADDRESS    3

XGpio gpio_btn;
XGpio gpio_sw;
XGpio gpio_led;


/*
 * Envoi d'une trame a l'IP :
 *   REG0 <- bits 31..0, REG1 <- bits 50..32,
 *   REG2 <- 1 : le FRONT MONTANT copie la trame dans le coeur (atomique),
 *   REG2 <- 0 : rearme la validation pour le prochain envoi.
 * Tant que REG2 n'a pas de front montant, le coeur continue d'emettre
 * l'ancienne trame : aucune trame partielle ne peut sortir.
 */
static void send_dcc_frame(u32 trame_low, u32 trame_high)
{
    CENTRALE_DCC_mWriteReg(DCC_BASE_ADDR, DCC_REG0_OFFSET, trame_low);
    CENTRALE_DCC_mWriteReg(DCC_BASE_ADDR, DCC_REG1_OFFSET, trame_high);
    CENTRALE_DCC_mWriteReg(DCC_BASE_ADDR, DCC_REG2_OFFSET, 0x00000001);
    CENTRALE_DCC_mWriteReg(DCC_BASE_ADDR, DCC_REG2_OFFSET, 0x00000000);
}

/* Delai actif simple, sert d'anti-rebond pour BTNU */
static void delay(int count)
{
    volatile int i, j;
    for (i = 0; i < count; i++)
        for (j = 0; j < 100000; j++);
}

static int init_gpio(XGpio *gpio, u16 id, u32 direction, const char *nom)
{
    if (XGpio_Initialize(gpio, id) != XST_SUCCESS) {
        xil_printf("ERREUR: init GPIO %s\r\n", nom);
        return -1;
    }
    XGpio_SetDataDirection(gpio, 1, direction);
    return 0;
}


int main(void)
{
    u32 sw_val, btn_val;
    u32 trame_low, trame_high;
    u8  cmd1, cmd2, step;
    int two_bytes;
    u16 led_val;
    u8  led_toggle = 0;
    u8  btn_prev   = 0;
    u8  cmd1_prev  = 0xFF;   /* force l'affichage de la 1re commande */
    u8  cmd2_prev  = 0xFF;

    xil_printf("=== Centrale DCC - Initialisation ===\r\n");

    if (init_gpio(&gpio_btn, GPIO_BTN_ID, 0xFFFFFFFF, "boutons")  ||
        init_gpio(&gpio_sw,  GPIO_SW_ID,  0xFFFFFFFF, "switches") ||
        init_gpio(&gpio_led, GPIO_LED_ID, 0x00000000, "LEDs"))
        return -1;

    /* Securite : trame d'arret au demarrage (l'IP en emet deja une au reset) */
    dcc_build_frame(TRAIN_ADDRESS, dcc_speed_command(1, 0), 0, 0,
                    &trame_low, &trame_high);
    send_dcc_frame(trame_low, trame_high);

    xil_printf("=== Systeme pret : SW[7:0] commande, SW[12:8] vitesse, BTNU envoi ===\r\n");

    while (1) {

        sw_val  = XGpio_DiscreteRead(&gpio_sw, 1);
        btn_val = XGpio_DiscreteRead(&gpio_btn, 1);

        u8 sw_cmd = sw_val & 0xFF;
        step      = (sw_val >> 8) & 0x1F;   /* sature a 28 dans dcc_speed_command */

        two_bytes = 0;
        cmd2      = 0;

        /* Decodage priorise des switches (SW7 prioritaire, comme en Phase 1) */
        if      (sw_cmd & 0x80) cmd1 = dcc_speed_command(1, step);  /* avant   */
        else if (sw_cmd & 0x40) cmd1 = dcc_speed_command(0, step);  /* arriere */
        else if (sw_cmd & 0x20) cmd1 = 0x90;                        /* F0 ON   */
        else if (sw_cmd & 0x10) cmd1 = 0x80;                        /* F0 OFF  */
        else if (sw_cmd & 0x08) cmd1 = 0xA4;                        /* F11 ON  */
        else if (sw_cmd & 0x04) cmd1 = 0xA0;                        /* F11 OFF */
        else if (sw_cmd & 0x02) { cmd1 = 0xDE; cmd2 = 0x01; two_bytes = 1; } /* F13 ON  */
        else if (sw_cmd & 0x01) { cmd1 = 0xDE; cmd2 = 0x00; two_bytes = 1; } /* F13 OFF */
        else                    cmd1 = dcc_speed_command(1, 0);     /* arret   */

        /* Affichage UART uniquement quand la commande CHANGE : un xil_printf
         * a chaque tour de boucle occuperait le JTAG UART en permanence et
         * degraderait la reactivite du bouton. */
        if (cmd1 != cmd1_prev || cmd2 != cmd2_prev) {
            xil_printf("Commande selectionnee : 0x%02X", cmd1);
            if (two_bytes)
                xil_printf(" 0x%02X", cmd2);
            xil_printf("\r\n");
            cmd1_prev = cmd1;
            cmd2_prev = cmd2;
        }

        /* LED[7:0] = octet de commande, LED[15] = bascule d'envoi */
        led_val = cmd1;
        if (led_toggle)
            led_val |= 0x8000;
        XGpio_DiscreteWrite(&gpio_led, 1, led_val);

        /* Envoi uniquement sur front montant de BTNU (pas en maintien) */
        u8 btn_up = btn_val & 0x01;

        if (btn_up && !btn_prev) {
            dcc_build_frame(TRAIN_ADDRESS, cmd1, cmd2, two_bytes,
                            &trame_low, &trame_high);
            send_dcc_frame(trame_low, trame_high);
            led_toggle = !led_toggle;
            xil_printf(">>> Trame envoyee : REG1=0x%05X REG0=0x%08X\r\n",
                       trame_high, trame_low);
        }

        btn_prev = btn_up;
        delay(5);
    }

    return 0;
}
