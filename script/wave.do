onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cordic_tb/cordic_top_u/u_cordic/clk
add wave -noupdate /cordic_tb/cordic_top_u/u_cordic/rst_n
add wave -noupdate -divider Input&Output
add wave -noupdate /cordic_tb/cordic_top_u/en_in
add wave -noupdate -radix unsigned /cordic_tb/cordic_top_u/mode_in
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/x_in
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/y_in
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/z_in
add wave -noupdate -divider {cordic core}
add wave -noupdate /cordic_tb/cordic_top_u/u_cordic/rotnvec_mode
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic/x_in
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic/y_in
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic/z_in
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic/x_out
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic/y_out
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic/z_out
add wave -noupdate -divider {gain comp}
add wave -noupdate /cordic_tb/cordic_top_u/u_cordic_gain_corr1/rotnvec_mode_in
add wave -noupdate /cordic_tb/cordic_top_u/u_cordic_gain_corr1/comp_mode
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_in
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic_gain_corr1/y_in
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic_gain_corr1/z_in
add wave -noupdate {/cordic_tb/cordic_top_u/mode_delay[25]}
add wave -noupdate -radix decimal -childformat {{{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[18]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[17]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[16]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[15]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[14]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[13]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[12]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[11]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[10]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[9]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[8]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[7]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[6]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[5]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[4]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[3]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[2]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[1]} -radix decimal} {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[0]} -radix decimal}} -subitemconfig {{/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[18]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[17]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[16]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[15]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[14]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[13]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[12]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[11]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[10]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[9]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[8]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[7]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[6]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[5]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[4]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[3]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[2]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[1]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out[0]} {-height 15 -radix decimal}} /cordic_tb/cordic_top_u/u_cordic_gain_corr1/x_out
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic_gain_corr1/y_out
add wave -noupdate -radix decimal /cordic_tb/cordic_top_u/u_cordic_gain_corr1/z_out
add wave -noupdate /cordic_tb/cordic_top_u/ready_out
add wave -noupdate -radix decimal -childformat {{{/cordic_tb/cordic_top_u/r_out[17]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[16]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[15]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[14]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[13]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[12]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[11]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[10]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[9]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[8]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[7]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[6]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[5]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[4]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[3]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[2]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[1]} -radix decimal} {{/cordic_tb/cordic_top_u/r_out[0]} -radix decimal}} -subitemconfig {{/cordic_tb/cordic_top_u/r_out[17]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[16]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[15]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[14]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[13]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[12]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[11]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[10]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[9]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[8]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[7]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[6]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[5]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[4]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[3]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[2]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[1]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/r_out[0]} {-height 15 -radix decimal}} /cordic_tb/cordic_top_u/r_out
add wave -noupdate -radix decimal -childformat {{{/cordic_tb/cordic_top_u/a_out[17]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[16]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[15]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[14]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[13]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[12]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[11]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[10]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[9]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[8]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[7]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[6]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[5]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[4]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[3]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[2]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[1]} -radix decimal} {{/cordic_tb/cordic_top_u/a_out[0]} -radix decimal}} -subitemconfig {{/cordic_tb/cordic_top_u/a_out[17]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[16]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[15]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[14]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[13]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[12]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[11]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[10]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[9]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[8]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[7]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[6]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[5]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[4]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[3]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[2]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[1]} {-height 15 -radix decimal} {/cordic_tb/cordic_top_u/a_out[0]} {-height 15 -radix decimal}} /cordic_tb/cordic_top_u/a_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1006 ns} 0} {{Cursor 2} {1351 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 127
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {722 ns} {1116 ns}
