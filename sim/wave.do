onerror {resume}
radix define fixed#24#decimal -fixed -fraction 24 -base signed -precision 17
radix define fixed#23#decimal -fixed -fraction 23 -base signed -precision 17
quietly WaveActivateNextPane {} 0
add wave -noupdate /pipelined_fpu_tb/dut/clk
add wave -noupdate /pipelined_fpu_tb/dut/reset
add wave -noupdate -radix unsigned /pipelined_fpu_tb/dut/op
add wave -noupdate /pipelined_fpu_tb/dut/start
add wave -noupdate -radix float32 /pipelined_fpu_tb/dut/operand_a
add wave -noupdate -radix float32 /pipelined_fpu_tb/dut/operand_b
add wave -noupdate /pipelined_fpu_tb/dut/stall
add wave -noupdate /pipelined_fpu_tb/dut/valid
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/result
add wave -noupdate -radix unsigned /pipelined_fpu_tb/dut/fpu_stage1_op
add wave -noupdate /pipelined_fpu_tb/dut/fpu_stage1_start
add wave -noupdate -radix float32 /pipelined_fpu_tb/dut/fpu_stage1_operand_a
add wave -noupdate -radix float32 /pipelined_fpu_tb/dut/fpu_stage1_operand_b
add wave -noupdate /pipelined_fpu_tb/dut/fpu_stage4_valid
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/fpu_stage4_result
add wave -noupdate /pipelined_fpu_tb/dut/valid_out
add wave -noupdate -radix float32 /pipelined_fpu_tb/dut/result_out
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/clk
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/reset
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/op
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/start
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/operand_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/operand_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/stall
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/valid
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/result
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_operand_sign_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_operand_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_operand_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_operand_sign_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_operand_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_operand_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_aligned_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_aligned_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_aligned_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_aligned_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_calculation_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_division_mode
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_division_op
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_normal_op
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_sticky_bit_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_result_sign
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_sign_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_exponent_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_fraction_msb_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage2_fraction_lsbs_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_operand_sign_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_operand_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_operand_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_operand_sign_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_operand_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_operand_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_remainder
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_calculated_exponent
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_calculated_fraction
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_sticky_bit_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_result_sign
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_result_valid
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_sign_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_exponent_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_fraction_msb_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fpu_stage3_fraction_lsbs_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/operand_sign_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/operand_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/operand_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/operand_sign_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/operand_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/operand_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/unbiased_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/unbiased_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/exchange_operands
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/align_shift_count
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/aligned_sign_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/aligned_sign_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/aligned_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/aligned_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/aligned_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/aligned_fraction_a_out
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/aligned_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/remainder
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/calculation_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/division_mode
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/division_op
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/normal_op
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/division_done
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/result_valid
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/calculated_exponent
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/calculated_fraction
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/normalized_exponent
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/normalized_fraction
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/normalize
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/rounding_mode
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/sticky_bit_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/result_sign
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/result_exponent
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/result_fraction
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/sign_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/exponent_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fraction_msb_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/fraction_lsbs_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/op
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/start
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/operand_sign_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/operand_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/operand_fraction_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/operand_sign_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/operand_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/operand_fraction_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/aligned_sign_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/aligned_exponent_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/aligned_sign_b
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/aligned_exponent_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exchange_operands
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/align_shift_count
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/aligned_fraction_a_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/result_sign
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/calculation_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/division_mode
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/division_op
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/normal_op
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/sticky_bit_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/sign_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exponent_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/fraction_msb_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/fraction_lsbs_select
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/operand_type_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/operand_type_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exponent_all_zeros_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exponent_all_ones_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/fraction_all_zeros_a
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exponent_all_zeros_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exponent_all_ones_b
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/fraction_all_zeros_b
add wave -noupdate -radix decimal /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exponent_difference
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exponent_over
add wave -noupdate /pipelined_fpu_tb/dut/pipelined_fpu/control_logic/exponent_under
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {29964800 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 413
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
WaveRestoreZoom {29023700 ps} {30177800 ps}
