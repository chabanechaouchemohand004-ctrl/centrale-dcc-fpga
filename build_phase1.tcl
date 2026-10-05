# ---------------------------------------------------------------------------
# Centrale DCC sur FPGA - reconstruction du projet Vivado de la Phase 1
# (VHDL pur, Basys 3) : creation du projet, synthese, implementation,
# bitstream.
#
#   vivado -mode batch -source build_phase1.tcl
#
# Resultat : build/vivado_phase1/  (bitstream dans .runs/impl_1/TOP_DCC.bit)
#
# NB : script non encore execute dans Vivado (ecrit apres le rendu du projet).
#      La Phase 2 (block design MicroBlaze) s'exporte depuis le projet
#      d'origine avec : write_bd_tcl -force bd/systeme_dcc.tcl
# ---------------------------------------------------------------------------

set root [file dirname [file normalize [info script]]]
set proj_dir "$root/build/vivado_phase1"

create_project centrale_dcc_phase1 $proj_dir -part xc7a35tcpg236-1 -force
set_property target_language VHDL [current_project]

add_files [glob $root/rtl/core/*.vhd]
add_files [glob $root/rtl/phase1/*.vhd]
add_files -fileset constrs_1 $root/constraints/Top_DCC_phase1.xdc
set_property top TOP_DCC [current_fileset]

# Testbenches (simulation Vivado)
add_files -fileset sim_1 [glob $root/sim/*.vhd]
set_property top TB_TOP_DCC_AUTO [get_filesets sim_1]
set_property file_type {VHDL 2008} [get_files -of_objects [get_filesets sim_1] *.vhd]

launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

open_run impl_1
report_timing_summary -file $proj_dir/timing_summary.rpt
report_utilization    -file $proj_dir/utilization.rpt
puts "=== Termine : bitstream dans $proj_dir/centrale_dcc_phase1.runs/impl_1/"
