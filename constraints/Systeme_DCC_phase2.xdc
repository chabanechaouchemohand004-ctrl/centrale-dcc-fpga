## ----------------------------------------------------------------------------
## Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
## TP Centrale DCC - Phase 2 (systeme MicroBlaze)
## Auteur : Mohand CHABANE CHAOUCHE
##
## Carte : Digilent Basys 3 (Artix-7 XC7A35T-1CPG236C)
##
## LEDs, switches, boutons, horloge et reset sont contraints automatiquement
## par les board interfaces Vivado (glisser-deposer depuis la vue Board du
## block design). Ce XDC ne contient donc que les ports custom non couverts
## par les board interfaces : ici, la sortie DCC vers le booster.
## ----------------------------------------------------------------------------

## Sortie DCC vers le booster : connecteur PMOD JB, broche physique JB4 (B16)
set_property PACKAGE_PIN B16 [get_ports Sortie_DCC_0]
    set_property IOSTANDARD LVCMOS33 [get_ports Sortie_DCC_0]
