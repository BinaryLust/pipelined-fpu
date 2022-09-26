onerror {resume}
radix define fixed#24#decimal -fixed -fraction 24 -base signed -precision 17
radix define fixed#23#decimal -fixed -fraction 23 -base signed -precision 17
quietly WaveActivateNextPane {} 0
add wave -noupdate /pipelined_fpu_tb/dut/clk
add wave -noupdate /pipelined_fpu_tb/dut/reset
add wave -noupdate /pipelined_fpu_tb/dut/op
add wave -noupdate /pipelined_fpu_tb/dut/start
add wave -noupdate /pipelined_fpu_tb/dut/a
add wave -noupdate /pipelined_fpu_tb/dut/b
add wave -noupdate /pipelined_fpu_tb/dut/done
add wave -noupdate /pipelined_fpu_tb/dut/busy
add wave -noupdate /pipelined_fpu_tb/dut/result
add wave -noupdate /pipelined_fpu_tb/dut/a_sign
add wave -noupdate /pipelined_fpu_tb/dut/a_exponent
add wave -noupdate /pipelined_fpu_tb/dut/a_fraction
add wave -noupdate /pipelined_fpu_tb/dut/b_sign
add wave -noupdate /pipelined_fpu_tb/dut/b_exponent
add wave -noupdate /pipelined_fpu_tb/dut/b_fraction
add wave -noupdate /pipelined_fpu_tb/dut/a_exponent_zeros
add wave -noupdate /pipelined_fpu_tb/dut/a_exponent_ones
add wave -noupdate /pipelined_fpu_tb/dut/a_fraction_zeros
add wave -noupdate /pipelined_fpu_tb/dut/b_exponent_zeros
add wave -noupdate /pipelined_fpu_tb/dut/b_exponent_ones
add wave -noupdate /pipelined_fpu_tb/dut/b_fraction_zeros
add wave -noupdate /pipelined_fpu_tb/dut/a_leading_zeros
add wave -noupdate /pipelined_fpu_tb/dut/a_norm_fraction
add wave -noupdate /pipelined_fpu_tb/dut/a_norm_exponent
add wave -noupdate /pipelined_fpu_tb/dut/b_leading_zeros
add wave -noupdate /pipelined_fpu_tb/dut/b_norm_fraction
add wave -noupdate /pipelined_fpu_tb/dut/b_norm_exponent
add wave -noupdate /pipelined_fpu_tb/dut/a_adj_fraction
add wave -noupdate /pipelined_fpu_tb/dut/a_adj_exponent
add wave -noupdate /pipelined_fpu_tb/dut/fract_sqrt
add wave -noupdate /pipelined_fpu_tb/dut/imm_exponent
add wave -noupdate /pipelined_fpu_tb/dut/imm_fraction
add wave -noupdate /pipelined_fpu_tb/dut/normalized_exponent
add wave -noupdate /pipelined_fpu_tb/dut/normalized_fraction
add wave -noupdate /pipelined_fpu_tb/dut/denormalize_shift_count
add wave -noupdate /pipelined_fpu_tb/dut/denormalized_exponent
add wave -noupdate /pipelined_fpu_tb/dut/denormalized_fraction
add wave -noupdate /pipelined_fpu_tb/dut/rounded_exponent
add wave -noupdate /pipelined_fpu_tb/dut/rounded_fraction
add wave -noupdate /pipelined_fpu_tb/dut/normalized_2_exponent
add wave -noupdate /pipelined_fpu_tb/dut/normalized_2_fraction
add wave -noupdate /pipelined_fpu_tb/dut/result_sign
add wave -noupdate /pipelined_fpu_tb/dut/fraction_lsb
add wave -noupdate /pipelined_fpu_tb/dut/round_bit
add wave -noupdate /pipelined_fpu_tb/dut/sticky_bit
add wave -noupdate /pipelined_fpu_tb/dut/a_zero
add wave -noupdate /pipelined_fpu_tb/dut/b_zero
add wave -noupdate /pipelined_fpu_tb/dut/abzero
add wave -noupdate /pipelined_fpu_tb/dut/zero
add wave -noupdate /pipelined_fpu_tb/dut/a_inf
add wave -noupdate /pipelined_fpu_tb/dut/b_inf
add wave -noupdate /pipelined_fpu_tb/dut/inf
add wave -noupdate /pipelined_fpu_tb/dut/a_nan
add wave -noupdate /pipelined_fpu_tb/dut/b_nan
add wave -noupdate /pipelined_fpu_tb/dut/nan
add wave -noupdate /pipelined_fpu_tb/dut/nnan
add wave -noupdate /pipelined_fpu_tb/dut/signal
add wave -noupdate /pipelined_fpu_tb/dut/a_denorm
add wave -noupdate /pipelined_fpu_tb/dut/b_denorm
add wave -noupdate /pipelined_fpu_tb/dut/denorm
add wave -noupdate /pipelined_fpu_tb/dut/result_over
add wave -noupdate /pipelined_fpu_tb/dut/result_denorm
add wave -noupdate /pipelined_fpu_tb/dut/result_under
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {200 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 295
configure wave -valuecolwidth 328
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {29400112400 ps} {29400115200 ps}
