## ----------------------------------------------------------------------------
## Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
## TP Centrale DCC
## Auteur : Mohand CHABANE CHAOUCHE
##
## Fichier de contraintes pour la centrale DCC sur Basys 3.
## Adapte du Basys-3-Master.xdc fourni par Digilent.
## ----------------------------------------------------------------------------

## Horloge 100 MHz
set_property PACKAGE_PIN W5 [get_ports CLK_100MHz]
    set_property IOSTANDARD LVCMOS33 [get_ports CLK_100MHz]
    create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK_100MHz]

## Reset = bouton central BTNC
set_property PACKAGE_PIN U18 [get_ports Reset]
    set_property IOSTANDARD LVCMOS33 [get_ports Reset]

## Interrupteurs SW0 a SW7
set_property PACKAGE_PIN W13 [get_ports {Interrupteur[7]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Interrupteur[7]}]

set_property PACKAGE_PIN W14 [get_ports {Interrupteur[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Interrupteur[6]}]

set_property PACKAGE_PIN V15 [get_ports {Interrupteur[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Interrupteur[5]}]

set_property PACKAGE_PIN W15 [get_ports {Interrupteur[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Interrupteur[4]}]

set_property PACKAGE_PIN W17 [get_ports {Interrupteur[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Interrupteur[3]}]

set_property PACKAGE_PIN W16 [get_ports {Interrupteur[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Interrupteur[2]}]

set_property PACKAGE_PIN V16 [get_ports {Interrupteur[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Interrupteur[1]}]

set_property PACKAGE_PIN V17 [get_ports {Interrupteur[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Interrupteur[0]}]

## Sortie DCC vers le booster : connecteur PMOD JB, broche JB4 (B16)
set_property PACKAGE_PIN B16 [get_ports Sortie_DCC]
    set_property IOSTANDARD LVCMOS33 [get_ports Sortie_DCC]
