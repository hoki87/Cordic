file copy -force ../src/cordic_inc.v ./

vlib work

vmap work work

vlog -work work  -sv ../src/op_quad_adj.v
vlog -work work  -sv ../src/ip_quad_info.v
vlog -work work  -sv ../src/ip_quad_adj.v
vlog -work work  -sv ../src/cordic_gain_corr.v
vlog -work work  -sv ../src/cordic_core.v
vlog -work work  -sv ../src/cordic.v
vlog -work work  -sv ../src/cordic_top.v
#vlog -work work  ./altera_mf.v
#vlog -work work  ./stratix_atoms.v
vlog -sv ../script/cordic_tb.v

vsim -novopt -t ns -L work cordic_tb

do ./wave.do
run 1.5us