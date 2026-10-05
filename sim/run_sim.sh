#!/usr/bin/env bash
# Lance tous les testbenches avec GHDL (https://github.com/ghdl/ghdl).
# Usage : ./sim/run_sim.sh   (depuis la racine du depot)
set -e
W=build/ghdl
mkdir -p "$W"
A="ghdl -a --std=08 --workdir=$W -fsynopsys"
R="ghdl --elab-run --std=08 --workdir=$W -fsynopsys"

# Ordre de compilation : feuilles d'abord
for f in rtl/core/Clk_Div.vhd rtl/core/Compteur_Tempo.vhd \
         rtl/core/DCC_Bit_0.vhd rtl/core/DCC_Bit_1.vhd \
         rtl/core/Registre_DCC.vhd rtl/core/MAE_DCC.vhd rtl/core/Coeur_DCC.vhd \
         rtl/phase1/Generateur_Trames.vhd rtl/phase1/Top_DCC.vhd \
         ip/Centrale_DCC/Centrale_DCC_v1_0_S00_AXI.vhd ip/Centrale_DCC/Centrale_DCC_v1_0.vhd \
         sim/*.vhd; do
    $A "$f"
done

for tb in TB_DCC_BIT_0 TB_DCC_BIT_1 TB_REGISTRE_DCC TB_GENERATEUR_TRAMES \
          TB_TOP_DCC_AUTO TB_CENTRALE_DCC_AXI; do
    echo "=== $tb"
    $R "$tb" --stop-time=200ms --assert-level=error
done
echo "=== Tous les testbenches sont passes."
