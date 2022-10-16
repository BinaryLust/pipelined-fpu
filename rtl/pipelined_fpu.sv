// special cases
// exponent // fraction
//      = 0 //      = 0 // zero
//      = 0 //     != 0 // subnormal // implicit leading bit of fraction is set to 0 instead of 1, also the exponent is always -126
//    = 255 //      = 0 // +/- infinity
//    = 255 //     != 0 // NaN (not a number) // leading bit of stored fraction(bit 23) determines if this is quiet(nontrapping) or signaling(trapping)
                        // trapping NaNs trigger an exception when they are used as an operand in any operation, quiet NaNs don't trigger an exception.


// exception types are overflow, underflow, division-by-zero, invalid operation, and inexact result
// have an exception enable bit for each exception, also a seperate exception bit for each exception
// these bits stay set until they are cleared by an exception handler
// overflow happens when the exponent is greater than 254 or (126)
// underflow happens when the exponent is less than 1 or (-126)
// or if submormal numbers are allowed underflow happens when the number
// is much smaller... fill this in later

// round to zero always just chops off the extra bits and never rounds or does anything at all

// round to plus infinity logic table
// sign // round bit // sticky bit // operation to do on fraction
//    +            0             0    nothing
//    +            0             1    add 1 to ulp
//    +            1             0    add 1 to ulp
//    +            1             1    add 1 to ulp
//    -            0             0    nothing
//    -            0             1    nothing
//    -            1             0    nothing
//    -            1             1    nothing

// round to minus infinity logic table
// sign // round bit // sticky bit // operation to do on fraction
//    +            0             0    nothing
//    +            0             1    nothing
//    +            1             0    nothing
//    +            1             1    nothing
//    -            0             0    nothing
//    -            0             1    add 1 to ulp
//    -            1             0    add 1 to ulp
//    -            1             1    add 1 to ulp

// for fused multiply add we could use carry save adders and do the addition and multiplication in parallel.

// logic usage on max 10, using balanced compilation settings.
// previous 1,499 LE, 168 regs, 7 9-bit multipliers, Fmax at 0C 274.57 MHz
// previous 1,411 LE, 86 regs,  7 9-bit multipliers, Fmax at 0C 227.01 MHz
// current  1,364 LE, 87 regs,  7 9-bit multipliers, Fmax at 0C 228.41 MHz


// for some reason we haven't added signaling nan's to the result selecter but we aren't getting errors.


// timing info
// fpu_stage 1 to fpu_stage 2 slack -12.281
// fpu_stage 2 to fpu_stage 3 slack -11.022
// fpu_stage 3 to fpu_stage 4 slack -15.609


module pipelined_fpu(
    input   logic          clk,
    input   logic          reset,
    input   logic  [2:0]   op,
    input   logic          start,
    input   logic  [31:0]  operand_a,
    input   logic  [31:0]  operand_b,

    output  logic          stall,
    output  logic          valid,
    output  logic  [31:0]  result
    );


    // stage 2 registers
    logic                                        fpu_stage2_operand_sign_a;
    logic                                [7:0]   fpu_stage2_operand_exponent_a;
    logic                                [23:0]  fpu_stage2_operand_fraction_a;
    logic                                        fpu_stage2_operand_sign_b;
    logic                                [7:0]   fpu_stage2_operand_exponent_b;
    logic                                [23:0]  fpu_stage2_operand_fraction_b;
    logic                                [7:0]   fpu_stage2_aligned_exponent_a;
    logic                                [7:0]   fpu_stage2_aligned_exponent_b;
    logic                                [23:0]  fpu_stage2_aligned_fraction_a;      // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    logic                                [48:0]  fpu_stage2_aligned_fraction_b;     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    calculation::calculation_select              fpu_stage2_calculation_select;
    logic                                        fpu_stage2_division_mode;
    logic                                        fpu_stage2_division_op;
    logic                                        fpu_stage2_normal_op;
    logic                                        fpu_stage2_sticky_bit_select;
    logic                                        fpu_stage2_result_sign;
    sign::sign_select                            fpu_stage2_sign_select;
    exponent::exponent_select                    fpu_stage2_exponent_select;
    fraction_msb::fraction_msb_select            fpu_stage2_fraction_msb_select;
    fraction_lsbs::fraction_lsbs_select          fpu_stage2_fraction_lsbs_select;


    // stage 3 registers
    logic                                        fpu_stage3_operand_sign_a;
    logic                                [7:0]   fpu_stage3_operand_exponent_a;
    logic                                [23:0]  fpu_stage3_operand_fraction_a;
    logic                                        fpu_stage3_operand_sign_b;
    logic                                [7:0]   fpu_stage3_operand_exponent_b;
    logic                                [23:0]  fpu_stage3_operand_fraction_b;
    logic                                [26:0]  fpu_stage3_remainder;
    logic                                [9:0]   fpu_stage3_calculated_exponent;
    logic                                [48:0]  fpu_stage3_calculated_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    logic                                        fpu_stage3_sticky_bit_select;
    logic                                        fpu_stage3_result_sign;
    logic                                        fpu_stage3_result_valid;
    sign::sign_select                            fpu_stage3_sign_select;
    exponent::exponent_select                    fpu_stage3_exponent_select;
    fraction_msb::fraction_msb_select            fpu_stage3_fraction_msb_select;
    fraction_lsbs::fraction_lsbs_select          fpu_stage3_fraction_lsbs_select;


    // combinational signals
    logic                                        operand_sign_a;
    logic                                [7:0]   operand_exponent_a;
    logic                                [23:0]  operand_fraction_a;

    logic                                        operand_sign_b;
    logic                                [7:0]   operand_exponent_b;
    logic                                [23:0]  operand_fraction_b;

    logic                                [7:0]   unbiased_exponent_a;
    logic                                [7:0]   unbiased_exponent_b;

    logic                                        exchange_operands;

    logic                                [4:0]   align_shift_count;
    logic                                        aligned_sign_a;
    logic                                        aligned_sign_b;
    logic                                [7:0]   aligned_exponent_a;
    logic                                [7:0]   aligned_exponent_b;
    logic                                [23:0]  aligned_fraction_a;     // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    logic                                [48:0]  aligned_fraction_b;     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    logic                                [26:0]  remainder;

    calculation::calculation_select              calculation_select;
    logic                                        division_mode;
    logic                                        division_op;
    logic                                        normal_op;
    logic                                        division_done;
    logic                                        result_valid;

    logic                                [9:0]   calculated_exponent;
    logic                                [48:0]  calculated_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    logic                                [9:0]   normalized_exponent;
    logic                                [48:0]  normalized_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    logic                                        sticky_bit_select;

    logic                                        result_sign;
    logic                                [9:0]   result_exponent;
    logic                                [24:0]  result_fraction;        // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits

    sign::sign_select                            sign_select;
    exponent::exponent_select                    exponent_select;
    fraction_msb::fraction_msb_select            fraction_msb_select;
    fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select;


    always_comb begin
        // unpack fields
        operand_sign_a     = operand_a[31];
        operand_exponent_a = operand_a[30:23];
        operand_fraction_a = {1'b1, operand_a[22:0]};  // add leading 1 bit to fraction, the leading bit will always be 1 because we treat subnormals as zero here.

        operand_sign_b     = operand_b[31];
        operand_exponent_b = operand_b[30:23];
        operand_fraction_b = {1'b1, operand_b[22:0]};  // add leading 1 bit to fraction, the leading bit will always be 1 because we treat subnormals as zero here.

        stall              = fpu_stage2_division_op & ~division_done;
        result_valid       = (fpu_stage2_division_op & division_done) | fpu_stage2_normal_op;
        valid              = fpu_stage3_result_valid;
    end


    control_logic
    control_logic(
        .op,
        .start,
        .operand_sign_a,
        .operand_exponent_a,
        .operand_fraction_a,
        .operand_sign_b,
        .operand_exponent_b,
        .operand_fraction_b,
        .aligned_sign_a,
        .aligned_exponent_a,
        .aligned_sign_b,
        .aligned_exponent_b,
        .exchange_operands,
        .align_shift_count,
        .result_sign,
        .calculation_select,
        .division_mode,
        .division_op,
        .normal_op,
        .sticky_bit_select,
        .sign_select,
        .exponent_select,
        .fraction_msb_select,
        .fraction_lsbs_select
    );


    exponent_bias_remover
    exponent_bias_remover(
        .operand_exponent_a,
        .operand_exponent_b,
        .unbiased_exponent_a,
        .unbiased_exponent_b
    );


    aligner
    aligner(
        .exchange_operands,
        .align_shift_count,
        .operand_sign_a,
        .unbiased_exponent_a,
        .operand_fraction_a,
        .operand_sign_b,
        .unbiased_exponent_b,
        .operand_fraction_b,
        .aligned_sign_a,
        .aligned_exponent_a,
        .aligned_fraction_a,
        .aligned_sign_b,
        .aligned_exponent_b,
        .aligned_fraction_b
    );


    fpu_registers_stage2
    fpu_registers_stage2(
        .clk,
        .reset,
        .stall,
        .operand_sign_a,
        .operand_exponent_a,
        .operand_fraction_a,
        .operand_sign_b,
        .operand_exponent_b,
        .operand_fraction_b,
        .aligned_exponent_a,
        .aligned_exponent_b,
        .aligned_fraction_a,
        .aligned_fraction_b,
        .result_sign,
        .calculation_select,
        .division_mode,
        .division_op,
        .normal_op,
        .sticky_bit_select,
        .sign_select,
        .exponent_select,
        .fraction_msb_select,
        .fraction_lsbs_select,
        .fpu_stage2_operand_sign_a,
        .fpu_stage2_operand_exponent_a,
        .fpu_stage2_operand_fraction_a,
        .fpu_stage2_operand_sign_b,
        .fpu_stage2_operand_exponent_b,
        .fpu_stage2_operand_fraction_b,
        .fpu_stage2_aligned_exponent_a,
        .fpu_stage2_aligned_exponent_b,
        .fpu_stage2_aligned_fraction_a,
        .fpu_stage2_aligned_fraction_b,
        .fpu_stage2_result_sign,
        .fpu_stage2_calculation_select,
        .fpu_stage2_division_mode,
        .fpu_stage2_division_op,
        .fpu_stage2_normal_op,
        .fpu_stage2_sticky_bit_select,
        .fpu_stage2_sign_select,
        .fpu_stage2_exponent_select,
        .fpu_stage2_fraction_msb_select,
        .fpu_stage2_fraction_lsbs_select
    );


    calculation_unit
    calculation_unit(
        .clk,
        .reset,    
        .calculation_select     (fpu_stage2_calculation_select),
        .division_mode          (fpu_stage2_division_mode),
        .division_op            (fpu_stage2_division_op),
        .aligned_exponent_a     (fpu_stage2_aligned_exponent_a),
        .aligned_fraction_a     (fpu_stage2_aligned_fraction_a),
        .aligned_exponent_b     (fpu_stage2_aligned_exponent_b),
        .aligned_fraction_b     (fpu_stage2_aligned_fraction_b),
        .done                   (division_done),
        .remainder,
        .calculated_exponent,
        .calculated_fraction
    );


    fpu_registers_stage3
    fpu_registers_stage3(
        .clk,
        .reset,
        .fpu_stage2_operand_sign_a,
        .fpu_stage2_operand_exponent_a,
        .fpu_stage2_operand_fraction_a,
        .fpu_stage2_operand_sign_b,
        .fpu_stage2_operand_exponent_b,
        .fpu_stage2_operand_fraction_b,
        .calculated_exponent,
        .calculated_fraction,
        .remainder,
        .fpu_stage2_result_sign,
        .result_valid,
        .fpu_stage2_sticky_bit_select,
        .fpu_stage2_sign_select,
        .fpu_stage2_exponent_select,
        .fpu_stage2_fraction_msb_select,
        .fpu_stage2_fraction_lsbs_select,
        .fpu_stage3_operand_sign_a,
        .fpu_stage3_operand_exponent_a,
        .fpu_stage3_operand_fraction_a,
        .fpu_stage3_operand_sign_b,
        .fpu_stage3_operand_exponent_b,
        .fpu_stage3_operand_fraction_b,
        .fpu_stage3_calculated_exponent,
        .fpu_stage3_calculated_fraction,
        .fpu_stage3_remainder,
        .fpu_stage3_result_sign,
        .fpu_stage3_result_valid,
        .fpu_stage3_sticky_bit_select,
        .fpu_stage3_sign_select,
        .fpu_stage3_exponent_select,
        .fpu_stage3_fraction_msb_select,
        .fpu_stage3_fraction_lsbs_select
    );


    normalizer
    normalizer(
        .calculated_exponent    (fpu_stage3_calculated_exponent),
        .calculated_fraction    (fpu_stage3_calculated_fraction),
        .normalized_exponent,
        .normalized_fraction
    );


    rounding_unit
    rounding_unit(
        .sticky_bit_select      (fpu_stage3_sticky_bit_select),
        .normalized_exponent,
        .normalized_fraction,
        .remainder              (fpu_stage3_remainder),
        .result_exponent,
        .result_fraction
    );


    result_selecter
    result_selecter(
        .sign_select             (fpu_stage3_sign_select),
        .exponent_select         (fpu_stage3_exponent_select),
        .fraction_msb_select     (fpu_stage3_fraction_msb_select),
        .fraction_lsbs_select    (fpu_stage3_fraction_lsbs_select),
        .operand_sign_a          (fpu_stage3_operand_sign_a),
        .operand_sign_b          (fpu_stage3_operand_sign_b),
        .operand_exponent_a      (fpu_stage3_operand_exponent_a),
        .operand_exponent_b      (fpu_stage3_operand_exponent_b),
        .operand_fraction_a      (fpu_stage3_operand_fraction_a),
        .operand_fraction_b      (fpu_stage3_operand_fraction_b),
        .result_sign             (fpu_stage3_result_sign),
        .result_exponent,
        .result_fraction,
        .result
    );


endmodule

