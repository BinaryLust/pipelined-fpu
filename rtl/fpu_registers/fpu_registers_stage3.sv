

module fpu_registers_stage3(
    input   logic                                        clk,
    input   logic                                        reset,
    input   logic                                        fpu_stage2_operand_sign_a,
    input   logic                                [7:0]   fpu_stage2_operand_exponent_a,
    input   logic                                [23:0]  fpu_stage2_operand_fraction_a,
    input   logic                                        fpu_stage2_operand_sign_b,
    input   logic                                [7:0]   fpu_stage2_operand_exponent_b,
    input   logic                                [23:0]  fpu_stage2_operand_fraction_b,
    input   logic                                [9:0]   calculated_exponent,
    input   logic                                [48:0]  calculated_fraction,           // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic                                [26:0]  remainder,
    input   logic                                        fpu_stage2_result_sign,
    input   logic                                        result_valid,
    input   logic                                        fpu_stage2_normalize,
    input   logic                                        fpu_stage2_rounding_mode,
    input   logic                                [1:0]   fpu_stage2_sticky_bit_select,
    input   sign::sign_select                            fpu_stage2_sign_select,
    input   exponent::exponent_select                    fpu_stage2_exponent_select,
    input   fraction_msb::fraction_msb_select            fpu_stage2_fraction_msb_select,
    input   fraction_lsbs::fraction_lsbs_select          fpu_stage2_fraction_lsbs_select,

    output  logic                                        fpu_stage3_operand_sign_a,
    output  logic                                [7:0]   fpu_stage3_operand_exponent_a,
    output  logic                                [23:0]  fpu_stage3_operand_fraction_a,
    output  logic                                        fpu_stage3_operand_sign_b,
    output  logic                                [7:0]   fpu_stage3_operand_exponent_b,
    output  logic                                [23:0]  fpu_stage3_operand_fraction_b,
    output  logic                                [9:0]   fpu_stage3_calculated_exponent,
    output  logic                                [48:0]  fpu_stage3_calculated_fraction,    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    output  logic                                [26:0]  fpu_stage3_remainder,
    output  logic                                        fpu_stage3_result_sign,
    output  logic                                        fpu_stage3_result_valid,
    output  logic                                        fpu_stage3_normalize,
    output  logic                                        fpu_stage3_rounding_mode,
    output  logic                                [1:0]   fpu_stage3_sticky_bit_select,
    output  sign::sign_select                            fpu_stage3_sign_select,
    output  exponent::exponent_select                    fpu_stage3_exponent_select,
    output  fraction_msb::fraction_msb_select            fpu_stage3_fraction_msb_select,
    output  fraction_lsbs::fraction_lsbs_select          fpu_stage3_fraction_lsbs_select
    );


    // data registers
    always_ff @(posedge clk) begin
        // data registers
        fpu_stage3_operand_sign_a       <= fpu_stage2_operand_sign_a;
        fpu_stage3_operand_exponent_a   <= fpu_stage2_operand_exponent_a;
        fpu_stage3_operand_fraction_a   <= fpu_stage2_operand_fraction_a;
        fpu_stage3_operand_sign_b       <= fpu_stage2_operand_sign_b;
        fpu_stage3_operand_exponent_b   <= fpu_stage2_operand_exponent_b;
        fpu_stage3_operand_fraction_b   <= fpu_stage2_operand_fraction_b;
        fpu_stage3_calculated_exponent  <= calculated_exponent;
        fpu_stage3_calculated_fraction  <= calculated_fraction;
        fpu_stage3_remainder            <= remainder;
        fpu_stage3_result_sign          <= fpu_stage2_result_sign;
    end


    // control control registers
    always_ff @(posedge clk or posedge reset) begin
        fpu_stage3_result_valid         <= (reset) ? 1'b0                 : result_valid;
        fpu_stage3_normalize            <= (reset) ? 1'b0                 : fpu_stage2_normalize;
        fpu_stage3_rounding_mode        <= (reset) ? 1'b0                 : fpu_stage2_rounding_mode;
        fpu_stage3_sticky_bit_select    <= (reset) ? 2'd0                 : fpu_stage2_sticky_bit_select;
        fpu_stage3_sign_select          <= (reset) ? sign::ZERO           : fpu_stage2_sign_select;
        fpu_stage3_exponent_select      <= (reset) ? exponent::ZEROS      : fpu_stage2_exponent_select;
        fpu_stage3_fraction_msb_select  <= (reset) ? fraction_msb::ZERO   : fpu_stage2_fraction_msb_select;
        fpu_stage3_fraction_lsbs_select <= (reset) ? fraction_lsbs::ZEROS : fpu_stage2_fraction_lsbs_select;
    end


endmodule

