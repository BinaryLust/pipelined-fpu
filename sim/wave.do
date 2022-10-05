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
add wave -noupdate /pipelined_fpu_tb/dut/sign_a
add wave -noupdate /pipelined_fpu_tb/dut/exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/sign_b
add wave -noupdate /pipelined_fpu_tb/dut/exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/exponent_all_zeros_a
add wave -noupdate /pipelined_fpu_tb/dut/exponent_all_ones_a
add wave -noupdate /pipelined_fpu_tb/dut/fraction_all_zeros_a
add wave -noupdate /pipelined_fpu_tb/dut/exponent_all_zeros_b
add wave -noupdate /pipelined_fpu_tb/dut/exponent_all_ones_b
add wave -noupdate /pipelined_fpu_tb/dut/fraction_all_zeros_b
add wave -noupdate /pipelined_fpu_tb/dut/operand_type_a
add wave -noupdate /pipelined_fpu_tb/dut/operand_type_b
add wave -noupdate /pipelined_fpu_tb/dut/exponent_less
add wave -noupdate /pipelined_fpu_tb/dut/exponent_equal
add wave -noupdate /pipelined_fpu_tb/dut/fraction_less
add wave -noupdate /pipelined_fpu_tb/dut/exchange_operands
add wave -noupdate /pipelined_fpu_tb/dut/sorted_sign_a
add wave -noupdate /pipelined_fpu_tb/dut/sorted_sign_b
add wave -noupdate /pipelined_fpu_tb/dut/sorted_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/sorted_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/sorted_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/sorted_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/align_shift_count_a
add wave -noupdate /pipelined_fpu_tb/dut/align_shift_count_b
add wave -noupdate /pipelined_fpu_tb/dut/aligned_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/aligned_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/root
add wave -noupdate /pipelined_fpu_tb/dut/quotient
add wave -noupdate /pipelined_fpu_tb/dut/sqrt_rem
add wave -noupdate /pipelined_fpu_tb/dut/div_rem
add wave -noupdate /pipelined_fpu_tb/dut/calculated_exponent
add wave -noupdate /pipelined_fpu_tb/dut/calculated_fraction
add wave -noupdate /pipelined_fpu_tb/dut/normalized_exponent
add wave -noupdate /pipelined_fpu_tb/dut/normalized_fraction
add wave -noupdate /pipelined_fpu_tb/dut/normalize_shift_count
add wave -noupdate /pipelined_fpu_tb/dut/fraction_lsb
add wave -noupdate /pipelined_fpu_tb/dut/guard_bit
add wave -noupdate /pipelined_fpu_tb/dut/round_bit
add wave -noupdate /pipelined_fpu_tb/dut/sticky_bit
add wave -noupdate /pipelined_fpu_tb/dut/rounded_exponent
add wave -noupdate /pipelined_fpu_tb/dut/rounded_fraction
add wave -noupdate /pipelined_fpu_tb/dut/post_sign
add wave -noupdate /pipelined_fpu_tb/dut/post_exponent
add wave -noupdate /pipelined_fpu_tb/dut/post_fraction
add wave -noupdate /pipelined_fpu_tb/dut/result_sign
add wave -noupdate /pipelined_fpu_tb/dut/result_exponent
add wave -noupdate /pipelined_fpu_tb/dut/result_fraction
add wave -noupdate /pipelined_fpu_tb/dut/sqrt_busy
add wave -noupdate /pipelined_fpu_tb/dut/sqrt_done
add wave -noupdate /pipelined_fpu_tb/dut/div_busy
add wave -noupdate /pipelined_fpu_tb/dut/div_done
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {145000 ps} 0}
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
WaveRestoreZoom {0 ps} {358400 ps}
