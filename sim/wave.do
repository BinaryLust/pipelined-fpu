onerror {resume}
radix define fixed#24#decimal -fixed -fraction 24 -base signed -precision 17
radix define fixed#23#decimal -fixed -fraction 23 -base signed -precision 17
quietly WaveActivateNextPane {} 0
add wave -noupdate /pipelined_fpu_tb/dut/clk
add wave -noupdate /pipelined_fpu_tb/dut/reset
add wave -noupdate /pipelined_fpu_tb/dut/op
add wave -noupdate /pipelined_fpu_tb/dut/start
add wave -noupdate /pipelined_fpu_tb/dut/operand_a
add wave -noupdate /pipelined_fpu_tb/dut/operand_b
add wave -noupdate /pipelined_fpu_tb/dut/done
add wave -noupdate /pipelined_fpu_tb/dut/busy
add wave -noupdate /pipelined_fpu_tb/dut/result
add wave -noupdate /pipelined_fpu_tb/dut/operand_sign_a
add wave -noupdate -radix unsigned /pipelined_fpu_tb/dut/operand_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/operand_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/operand_sign_b
add wave -noupdate -radix unsigned /pipelined_fpu_tb/dut/operand_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/operand_fraction_b
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/unbiased_exponent_a
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/unbiased_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/exchange_operands
add wave -noupdate /pipelined_fpu_tb/dut/sorted_sign_a
add wave -noupdate /pipelined_fpu_tb/dut/sorted_sign_b
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/sorted_exponent_a
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/sorted_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/sorted_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/sorted_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/align_shift_count
add wave -noupdate /pipelined_fpu_tb/dut/aligned_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/remainder
add wave -noupdate /pipelined_fpu_tb/dut/calculation_select
add wave -noupdate /pipelined_fpu_tb/dut/divider_mode
add wave -noupdate /pipelined_fpu_tb/dut/divider_start
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/calculated_exponent
add wave -noupdate /pipelined_fpu_tb/dut/calculated_fraction
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/normalized_exponent
add wave -noupdate /pipelined_fpu_tb/dut/normalized_fraction
add wave -noupdate /pipelined_fpu_tb/dut/sticky_bit_select
add wave -noupdate /pipelined_fpu_tb/dut/result_sign
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/result_exponent
add wave -noupdate /pipelined_fpu_tb/dut/result_fraction
add wave -noupdate /pipelined_fpu_tb/dut/sign_select
add wave -noupdate /pipelined_fpu_tb/dut/exponent_select
add wave -noupdate /pipelined_fpu_tb/dut/fraction_msb_select
add wave -noupdate /pipelined_fpu_tb/dut/fraction_lsbs_select
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {471795000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 290
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
WaveRestoreZoom {471615500 ps} {471974500 ps}
