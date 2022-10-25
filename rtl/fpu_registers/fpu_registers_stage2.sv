

module fpu_registers_stage2(
    input   logic                                        clk,
    input   logic                                        reset,
    input   logic                                        stall,
    input   logic                                        operand_sign_a,
    input   logic                                [7:0]   operand_exponent_a,
    input   logic                                [23:0]  operand_fraction_a,
    input   logic                                        operand_sign_b,
    input   logic                                [7:0]   operand_exponent_b,
    input   logic                                [23:0]  operand_fraction_b,
    input   logic                                        aligned_sign_b,
    input   logic                                [7:0]   aligned_exponent_a,
    input   logic                                [7:0]   aligned_exponent_b,
    input   logic                                [23:0]  aligned_fraction_a,              // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    input   logic                                [48:0]  aligned_fraction_b,              // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic                                        result_sign,
    input   logic                                        aligned_fraction_a_select,
    input   logic                                        aligned_exponent_b_select,
    input   logic                                        aligned_fraction_b_select,
    input   calc1::exponent_select                       calculation_exponent_select,
    input   calc2::fraction_select                       calculation_fraction_select,
    input   logic                                        division_mode,
    input   logic                                        division_op,
    input   logic                                        normal_op,
    input   logic                                        normalize,
    input   logic                                        rounding_mode,
    input   logic                                [1:0]   sticky_bit_select,
    input   logic                                        check_result,
    input   sign::sign_select                            sign_select,
    input   exponent::exponent_select                    exponent_select,
    input   fraction_msb::fraction_msb_select            fraction_msb_select,
    input   fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select,

    output  logic                                        fpu_stage2_operand_sign_a,
    output  logic                                [7:0]   fpu_stage2_operand_exponent_a,
    output  logic                                [23:0]  fpu_stage2_operand_fraction_a,
    output  logic                                        fpu_stage2_operand_sign_b,
    output  logic                                [7:0]   fpu_stage2_operand_exponent_b,
    output  logic                                [23:0]  fpu_stage2_operand_fraction_b,
    output  logic                                        fpu_stage2_aligned_sign_b,
    output  logic                                [7:0]   fpu_stage2_aligned_exponent_a,
    output  logic                                [7:0]   fpu_stage2_aligned_exponent_b,
    output  logic                                [23:0]  fpu_stage2_aligned_fraction_a,   // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    output  logic                                [48:0]  fpu_stage2_aligned_fraction_b,   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    output  logic                                        fpu_stage2_result_sign,
    output  logic                                        fpu_stage2_aligned_fraction_a_select,
    output  logic                                        fpu_stage2_aligned_exponent_b_select,
    output  logic                                        fpu_stage2_aligned_fraction_b_select,
    output  calc1::exponent_select                       fpu_stage2_calculation_exponent_select,
    output  calc2::fraction_select                       fpu_stage2_calculation_fraction_select,
    output  logic                                        fpu_stage2_division_mode,
    output  logic                                        fpu_stage2_division_op,
    output  logic                                        fpu_stage2_normal_op,
    output  logic                                        fpu_stage2_normalize,
    output  logic                                        fpu_stage2_rounding_mode,
    output  logic                                [1:0]   fpu_stage2_sticky_bit_select,
    output  logic                                        fpu_stage2_check_result,
    output  sign::sign_select                            fpu_stage2_sign_select,
    output  exponent::exponent_select                    fpu_stage2_exponent_select,
    output  fraction_msb::fraction_msb_select            fpu_stage2_fraction_msb_select,
    output  fraction_lsbs::fraction_lsbs_select          fpu_stage2_fraction_lsbs_select
    );


    // data registers
    always_ff @(posedge clk) begin
        // data registers
        fpu_stage2_operand_sign_a       <= (stall) ? fpu_stage2_operand_sign_a     : operand_sign_a;
        fpu_stage2_operand_exponent_a   <= (stall) ? fpu_stage2_operand_exponent_a : operand_exponent_a;
        fpu_stage2_operand_fraction_a   <= (stall) ? fpu_stage2_operand_fraction_a : operand_fraction_a;
        fpu_stage2_operand_sign_b       <= (stall) ? fpu_stage2_operand_sign_b     : operand_sign_b;
        fpu_stage2_operand_exponent_b   <= (stall) ? fpu_stage2_operand_exponent_b : operand_exponent_b;
        fpu_stage2_operand_fraction_b   <= (stall) ? fpu_stage2_operand_fraction_b : operand_fraction_b;
        fpu_stage2_aligned_sign_b       <= (stall) ? fpu_stage2_aligned_sign_b     : aligned_sign_b;
        fpu_stage2_aligned_exponent_a   <= (stall) ? fpu_stage2_aligned_exponent_a : aligned_exponent_a;
        fpu_stage2_aligned_fraction_a   <= (stall) ? fpu_stage2_aligned_fraction_a : aligned_fraction_a;
        fpu_stage2_aligned_exponent_b   <= (stall) ? fpu_stage2_aligned_exponent_b : aligned_exponent_b;
        fpu_stage2_aligned_fraction_b   <= (stall) ? fpu_stage2_aligned_fraction_b : aligned_fraction_b;
        fpu_stage2_result_sign          <= (stall) ? fpu_stage2_result_sign        : result_sign;
    end


    // control registers
    always_ff @(posedge clk or posedge reset) begin
        fpu_stage2_aligned_fraction_a_select   <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_aligned_fraction_a_select   : aligned_fraction_a_select;
        fpu_stage2_aligned_exponent_b_select   <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_aligned_exponent_b_select   : aligned_exponent_b_select;
        fpu_stage2_aligned_fraction_b_select   <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_aligned_fraction_b_select   : aligned_fraction_b_select;
        fpu_stage2_calculation_exponent_select <= (reset) ? calc1::A             : (stall) ? fpu_stage2_calculation_exponent_select : calculation_exponent_select;
        fpu_stage2_calculation_fraction_select <= (reset) ? calc2::ADD           : (stall) ? fpu_stage2_calculation_fraction_select : calculation_fraction_select;
        fpu_stage2_division_mode               <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_division_mode               : division_mode;
        fpu_stage2_division_op                 <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_division_op                 : division_op;
        fpu_stage2_normal_op                   <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_normal_op                   : normal_op;
        fpu_stage2_normalize                   <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_normalize                   : normalize;
        fpu_stage2_rounding_mode               <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_rounding_mode               : rounding_mode;
        fpu_stage2_sticky_bit_select           <= (reset) ? 2'd0                 : (stall) ? fpu_stage2_sticky_bit_select           : sticky_bit_select;
        fpu_stage2_check_result                <= (reset) ? 1'b0                 : (stall) ? fpu_stage2_check_result                : check_result;
        fpu_stage2_sign_select                 <= (reset) ? sign::ZERO           : (stall) ? fpu_stage2_sign_select                 : sign_select;
        fpu_stage2_exponent_select             <= (reset) ? exponent::ZEROS      : (stall) ? fpu_stage2_exponent_select             : exponent_select;
        fpu_stage2_fraction_msb_select         <= (reset) ? fraction_msb::ZERO   : (stall) ? fpu_stage2_fraction_msb_select         : fraction_msb_select;
        fpu_stage2_fraction_lsbs_select        <= (reset) ? fraction_lsbs::ZEROS : (stall) ? fpu_stage2_fraction_lsbs_select        : fraction_lsbs_select;
    end


endmodule

