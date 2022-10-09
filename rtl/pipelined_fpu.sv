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
// previous 1,499 LE, 168 regs, 7 9-bit multipliers, Fmax at 0C, 274.57 MHz


module pipelined_fpu(
    input   logic          clk,
    input   logic          reset,
    input   logic  [2:0]   op,
    input   logic          start,
    input   logic  [31:0]  a,
    input   logic  [31:0]  b,

    output  logic          done,
    output  logic          busy,
    output  logic  [31:0]  result
    );


    logic                                        sign_a;
    logic                                [7:0]   exponent_a;
    logic                                [23:0]  fraction_a;

    logic                                        sign_b;
    logic                                [7:0]   exponent_b;
    logic                                [23:0]  fraction_b;

    logic                                        exchange_operands;

    logic                                        sorted_sign_a;
    logic                                        sorted_sign_b;
    logic                                [7:0]   sorted_exponent_a;
    logic                                [7:0]   sorted_exponent_b;
    logic                                [23:0]  sorted_fraction_a;      // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    logic                                [23:0]  sorted_fraction_b;      // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits

    logic                                [4:0]   align_shift_count;
    logic                                [48:0]  aligned_fraction_b;     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    logic                                [26:0]  remainder;

    calculation::calculation_select              calculation_select;
    logic                                        divider_mode;
    logic                                        divider_start;

    logic                                [9:0]   calculated_exponent;
    logic                                [48:0]  calculated_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    logic                                [9:0]   normalized_exponent;
    logic                                [48:0]  normalized_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    logic                                        result_sign;
    logic                                [9:0]   result_exponent;
    logic                                [24:0]  result_fraction;        // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits

    sign::sign_select                            sign_select;
    exponent::exponent_select                    exponent_select;
    fraction_msb::fraction_msb_select            fraction_msb_select;
    fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select;


    always_comb begin
        // unpack fields
        sign_a           = a[31];
        exponent_a       = a[30:23];
        fraction_a       = {1'b1, a[22:0]};  // add leading 1 bit to fraction, the leading bit will always be 1 because we treat subnormals as zero here.

        sign_b           = b[31];
        exponent_b       = b[30:23];
        fraction_b       = {1'b1, b[22:0]};  // add leading 1 bit to fraction, the leading bit will always be 1 because we treat subnormals as zero here.


        // do alignment, this is done by the aligner module below.
        // do calculation, this is done by the calculation_unit module below.
        // do normalization, this is done by the normalizer module below.
        // do rounding, this is done by the rounding_logic module below.
        // select final result and pack fields, this is done by the result_selecter and control_logic modules.
    end


    control_logic
    control_logic(
        .op,
        .start,
        .sign_a,
        .exponent_a,
        .fraction_a,
        .sign_b,
        .exponent_b,
        .fraction_b,
        .sorted_sign_a,
        .sorted_exponent_a,
        .sorted_sign_b,
        .sorted_exponent_b,
        .exchange_operands,
        .align_shift_count,
        .result_sign,
        .calculation_select,
        .divider_mode,
        .divider_start,
        .sign_select,
        .exponent_select,
        .fraction_msb_select,
        .fraction_lsbs_select
    );


    aligner
    aligner(
        .exchange_operands,
        .align_shift_count,
        .sign_a,
        .exponent_a,
        .fraction_a,
        .sign_b,
        .exponent_b,
        .fraction_b,
        .sorted_sign_a,
        .sorted_exponent_a,
        .sorted_fraction_a,
        .sorted_sign_b,
        .sorted_exponent_b,
        .sorted_fraction_b,
        .aligned_fraction_b
    );


    calculation_unit
    calculation_unit(
        .clk,
        .reset,    
        .calculation_select,
        .divider_mode,
        .divider_start,
        .sorted_exponent_a,
        .sorted_fraction_a,
        .sorted_exponent_b,
        .aligned_fraction_b,
        .busy,
        .done,
        .remainder,
        .calculated_exponent,
        .calculated_fraction
    );


    normalizer
    normalizer(
        .calculated_exponent,
        .calculated_fraction,
        .normalized_exponent,
        .normalized_fraction
    );


    rounding_logic
    rounding_logic(
        .op,
        .normalized_exponent,
        .normalized_fraction,
        .remainder,
        .result_exponent,
        .result_fraction
    );


    result_selecter
    result_selecter(
        .sign_select,
        .exponent_select,
        .fraction_msb_select,
        .fraction_lsbs_select,
        .sign_a,
        .sign_b,
        .exponent_a,
        .exponent_b,
        .fraction_a,
        .fraction_b,
        .result_sign,
        .result_exponent,
        .result_fraction,
        .result
    );


endmodule

