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

// below is all the combinations the result can be
// result = {result_sign,       8'd255,      23'd0};        // add, sub, mul, div, overflow: +/- infinity
// result = {1'b0,              8'd255,      23'd0};        // sqrt: if sign_a is 0 then +infinity
// result = {1'b1,              8'd255,      1'b1, 22'd0};  // add, sub, mul, div, sqrt: -1.#IND
// result = {sign_a,            exponent_a,  fraction_a};   // add, sub: a
// result = {sign_b,            exponent_b,  fraction_b};   // add: b
// result = {~sign_b,           exponent_b,  fraction_b};   // sub: b
// result = {sign_a & sign_b,   8'd0,        23'd0};        // add: zero + zero = zero
// result = {sign_a & ~sign_b,  8'd0,        23'd0};        // sub: zero + zero = zero
// result = {result_sign,       8'd0,        23'd0};        // mul, div, subnormal, underflow: +/- zero
// result = {sign_a,            8'd0,        23'd0};        // sqrt: +/- zero
// result = {1'b0,              8'd0,        23'd0};        // add, sub only?: zero
// result = {sign_a,            8'd255,      1'b1, fraction_a[21:0]};  // (NaN * 1NaN)
// result = {1'b0,              8'd255,      1'b1, fraction_a[21:0]};  // sqrt: quiet not a number (following x86 standards)
// result = {1'b1,              8'd255,      1'b1, fraction_a[21:0]};  // sqrt: negative quiet not a number (following x86 standards)
// result = {1'b0,              8'd255,      1'b1, (is_nan_a) ? fraction_a[21:0] : fraction_b[21:0]};  // mul, div:  quiet not a number (following x86 standards)
// result = {1'b1,              8'd255,      1'b1, (is_nan_a) ? fraction_a[21:0] : fraction_b[21:0]};  // add, sub, mul, div:  negative quiet not a number (following x86 standards)
// result = {1'b0,              result_exponent[7:0],   result_fraction[22:0]};  // sqrt: sign_a == 0 then normal result
// result = {result_sign,       result_exponent[7:0],   result_fraction[22:0]};  // add, sub, mult, div: normal result

// sign can be
// 1'b0
// 1'b1
// sign_a
// sign_b
// sign_a & sign_b
// sign_a & ~sign_b
// result_sign

// exponent can be
// 8'd0
// 8'd255
// exponent_a
// exponent_b
// result_exponent[7:0]

// fraction bit 23 can be
// 1'b0
// 1'b1
// fraction_a[22]
// fraction_b[22]
// result_fraction[22]

// fraction bits 22:0 can be
// 22'd0
// fraction_a[21:0]
// fraction_b[21:0]
// result_fraction[21:0]


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


    import fpu::*;


    logic          sign_a;
    logic  [7:0]   exponent_a;
    logic  [23:0]  fraction_a;


    logic          sign_b;
    logic  [7:0]   exponent_b;
    logic  [23:0]  fraction_b;


    operand_types  operand_type_a;
    operand_types  operand_type_b;


    logic          exchange_operands;


    logic          sorted_sign_a;
    logic          sorted_sign_b;
    logic  [7:0]   sorted_exponent_a;
    logic  [7:0]   sorted_exponent_b;
    logic  [23:0]  sorted_fraction_a;      // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    logic  [23:0]  sorted_fraction_b;      // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits


    logic  [47:0]  right_shifter_result;   // is [x.xxxx...]  format with 1 integer bit,  47 fractional bits


    logic  [4:0]   align_shift_count;
    logic  [48:0]  aligned_fraction_b;     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits


    logic  [25:0]  quotient_root;          // is [x.xxxx...]  format with 1 integer bits  25 fractional bits
    logic  [26:0]  remainder;


    logic  [9:0]   calculated_exponent;
    logic  [48:0]  calculated_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits


    logic  [48:0]  left_shifter_result;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits


    logic  [9:0]   normalized_exponent;
    logic  [48:0]  normalized_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    logic  [4:0]   normalize_shift_count;    


    logic          post_sign;
    logic  [9:0]   post_exponent;
    logic  [24:0]  post_fraction;          // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits


    logic          result_sign;
    logic  [9:0]   result_exponent;
    logic  [24:0]  result_fraction;        // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits


    always_comb begin
        // unpack fields
        sign_a           = a[31];
        exponent_a       = a[30:23];
        fraction_a       = {1'b1, a[22:0]};  // add leading 1 bit to fraction, the leading bit will always be 1 because we treat subnormals as zero here.

        sign_b           = b[31];
        exponent_b       = b[30:23];
        fraction_b       = {1'b1, b[22:0]};  // add leading 1 bit to fraction, the leading bit will always be 1 because we treat subnormals as zero here.


        // sort operands, we will only do this for addition and subtraction operations, for all other operations we just pass the values through.
        // the sorting is done by the operand exchanger module below.


        // do alignment
        // this is done by the right_shifter module below.
        aligned_fraction_b  = {1'b0, right_shifter_result};
        // aligned_exponent_a = 
        // aligned_exponent_b =


        // do calculation
        casex(op)
            3'd0:       begin
                            calculated_exponent = sorted_exponent_a;
                            calculated_fraction = (sorted_sign_a ^ sorted_sign_b) ? unsigned'({1'd0, sorted_fraction_a, 24'd0}) - unsigned'(aligned_fraction_b)
                                                                                  : unsigned'({1'd0, sorted_fraction_a, 24'd0}) + unsigned'(aligned_fraction_b);
                        end

            3'd1:       begin
                            calculated_exponent = sorted_exponent_a;
                            calculated_fraction = (sorted_sign_a ~^ sorted_sign_b) ? unsigned'({1'd0, sorted_fraction_a, 24'd0}) - unsigned'(aligned_fraction_b)
                                                                                   : unsigned'({1'd0, sorted_fraction_a, 24'd0}) + unsigned'(aligned_fraction_b);
                        end

            3'd2:       begin // for multiplication // add exponents and multiply fractions
                            calculated_exponent = (unsigned'(sorted_exponent_a) + unsigned'(sorted_exponent_b)) - 10'd127;
                            calculated_fraction = (unsigned'(sorted_fraction_a) * unsigned'(aligned_fraction_b[47:24])) << 1;
                        end

            3'd3:       begin // for division
                            calculated_exponent = (unsigned'(sorted_exponent_a) - unsigned'(sorted_exponent_b)) + 10'd127;
                            calculated_fraction = {1'b0, quotient_root, 22'd0}; // quotient is 26-bits wide
                        end

            default:    begin // for square root // find the sqrt of the fraction
                            calculated_exponent = (sorted_exponent_b[7:1] + 10'd63) + sorted_exponent_b[0];  // this divides the exponent by 2, adds half the bias back in and if it was odd before increments the value by 1.
                            calculated_fraction = {1'b0, quotient_root, 22'd0}; // root is 26-bits wide
                        end
        endcase


        // do normalization
        casex(calculated_fraction[48:47])
            2'b1?:      begin // number overflowed right shift by 1, used for add, sub, and mul
                            normalized_fraction = calculated_fraction >> 1;
                            normalized_exponent = calculated_exponent + 10'd1;
                        end
            2'b01:      begin // number already normalized
                            normalized_fraction = calculated_fraction;
                            normalized_exponent = calculated_exponent;
                        end
            default:    begin // number underflowed left shift, shifting by 1 used by div, shifting by more than 1 used by add and sub.
                            normalized_fraction = left_shifter_result;
                            normalized_exponent = calculated_exponent - normalize_shift_count;
                        end
        endcase


        // do rounding
        // this is done by the rounding_logic module below.


        // set final result values
        if(~|post_fraction) begin // check for zero
            // set zero as result
            result_sign     = 1'b0;
            result_exponent = 10'd0;
            result_fraction = 25'd0;
        end else if(post_exponent >=  10'd255 && post_exponent <=  10'd511) begin // check for overflow
            // set infinity as result
            result_sign     = post_sign;
            result_exponent = 8'd255;
            result_fraction = 25'd0;
        end else if(post_exponent == 10'd0 || (post_exponent <=  -10'd1 && post_exponent >= -10'd512)) begin // check for underflow
            // set zero as result
            result_sign     = post_sign;
            result_exponent = 10'd0;
            result_fraction = 25'd0;
        end else begin
            // use actual results
            result_sign     = post_sign;
            result_exponent = post_exponent;
            result_fraction = post_fraction;
        end


        // select final result and pack fields
        casex({op, operand_type_a, operand_type_b, sign_a, sign_b})
            // 8'b0?0??01? // is_infinite
            {3'd0, INFINITE,  NORMAL,    1'b?, 1'b?},
            {3'd0, NORMAL,    INFINITE,  1'b?, 1'b?}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // add: +/- infinity
            {3'd0, INFINITE,  INFINITE,  1'b1, 1'b0},
            {3'd0, INFINITE,  INFINITE,  1'b0, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // add: -1.#IND
            {3'd0, INFINITE,  INFINITE,  1'b0, 1'b0},
            {3'd0, INFINITE,  INFINITE,  1'b1, 1'b1}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // add: +/- infinity

            {3'd1, INFINITE,  NORMAL,    1'b?, 1'b?},
            {3'd1, NORMAL,    INFINITE,  1'b?, 1'b?}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // sub: +/- infinity
            {3'd1, INFINITE,  INFINITE,  1'b0, 1'b0},
            {3'd1, INFINITE,  INFINITE,  1'b1, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // sub: -1.#IND
            {3'd1, INFINITE,  INFINITE,  1'b0, 1'b1},
            {3'd1, INFINITE,  INFINITE,  1'b1, 1'b0}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // sub: +/- infinity

            {3'd2, INFINITE,  NORMAL,    1'b?, 1'b?},
            {3'd2, NORMAL,    INFINITE,  1'b?, 1'b?},
            {3'd2, INFINITE,  INFINITE,  1'b?, 1'b?}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // mul:  (num * infinity) = infinity

            {3'd3, INFINITE,  NORMAL,    1'b?, 1'b?}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // div: +/- infinity
            {3'd3, NORMAL,    INFINITE,  1'b?, 1'b?}: result = {result_sign,       8'd0,                  1'b0,                 22'd0};                  // div: +/- zero
            {3'd3, INFINITE,  INFINITE,  1'b?, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // div: -1.#IND

            {3'd4, DONTCARE,  INFINITE,  1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // sqrt: if sign_a is 1 then -1.#IND
            {3'd4, DONTCARE,  INFINITE,  1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b0,                 22'd0};                  // sqrt: if sign_a is 0 then +infinity

            // 8'b0?0??10? // is_zero
            {3'd0, NORMAL,    ZERO,      1'b?, 1'b?},
            {3'd0, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: result = {sign_a,            exponent_a,            fraction_a[22],       fraction_a[21:0]};       // add: a
            {3'd0, ZERO,      NORMAL,    1'b?, 1'b?},
            {3'd0, SUBNORMAL, NORMAL,    1'b?, 1'b?}: result = {sign_b,            exponent_b,            fraction_b[22],       fraction_b[21:0]};       // add: b
            {3'd0, ZERO,      ZERO,      1'b?, 1'b?},
            {3'd0, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {3'd0, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {3'd0, SUBNORMAL, ZERO,      1'b?, 1'b?}: result = {sign_a & sign_b,   8'd0,                  1'b0,                 22'd0};                  // add: zero + zero = zero

            {3'd1, NORMAL,    ZERO,      1'b?, 1'b?},
            {3'd1, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: result = {sign_a,            exponent_a,            fraction_a[22],       fraction_a[21:0]};       // sub: a
            {3'd1, ZERO,      NORMAL,    1'b?, 1'b?},
            {3'd1, SUBNORMAL, NORMAL,    1'b?, 1'b?}: result = {~sign_b,           exponent_b,            fraction_b[22],       fraction_b[21:0]};       // sub: b
            {3'd1, ZERO,      ZERO,      1'b?, 1'b?},
            {3'd1, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {3'd1, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {3'd1, SUBNORMAL, ZERO,      1'b?, 1'b?}: result = {sign_a & ~sign_b,  8'd0,                  1'b0,                 22'd0};                  // sub: zero + zero = zero

            {3'd2, NORMAL,    ZERO,      1'b?, 1'b?},
            {3'd2, NORMAL,    SUBNORMAL, 1'b?, 1'b?},
            {3'd2, ZERO,      NORMAL,    1'b?, 1'b?},
            {3'd2, SUBNORMAL, NORMAL,    1'b?, 1'b?},
            {3'd2, ZERO,      ZERO,      1'b?, 1'b?},
            {3'd2, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {3'd2, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {3'd2, SUBNORMAL, ZERO,      1'b?, 1'b?}: result = {result_sign,       8'd0,                  1'b0,                 22'd0};                  // mul:  (num * zero) = zero

            {3'd3, NORMAL,    ZERO,      1'b?, 1'b?},
            {3'd3, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // div: +/- infinity
            {3'd3, ZERO,      NORMAL,    1'b?, 1'b?},
            {3'd3, SUBNORMAL, NORMAL,    1'b?, 1'b?}: result = {result_sign,       8'd0,                  1'b0,                 22'd0};                  // div: +/- zero
            {3'd3, ZERO,      ZERO,      1'b?, 1'b?},
            {3'd3, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {3'd3, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {3'd3, SUBNORMAL, ZERO,      1'b?, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // div: -1.#IND

            {3'd4, DONTCARE,  ZERO,      1'b?, 1'b?},
            {3'd4, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: result = {sign_b,            8'd0,                  1'b0,                 22'd0};                  // sqrt: +/- zero

            // 8'b1?1????? // is_nnan and is_nan
            {3'd0, NAN,       NAN,       1'b0, 1'b1},
            {3'd0, NAN,       NAN,       1'b1, 1'b0}: result = {sign_a,            8'd255,                1'b1,                 fraction_a[21:0]};       // add: NaN

            {3'd1, NAN,       NAN,       1'b0, 1'b1},
            {3'd1, NAN,       NAN,       1'b1, 1'b0}: result = {sign_a,            8'd255,                1'b1,                 fraction_a[21:0]};       // sub: NaN

            {3'd2, NAN,       NAN,       1'b0, 1'b1},
            {3'd2, NAN,       NAN,       1'b1, 1'b0}: result = {sign_a,            8'd255,                1'b1,                 fraction_a[21:0]};       // mul: NaN

            {3'd3, NAN,       NAN,       1'b0, 1'b1},
            {3'd3, NAN,       NAN,       1'b1, 1'b0}: result = {sign_a,            8'd255,                1'b1,                 fraction_a[21:0]};       // div: NaN

            // 8'b0?0??11? // is_zero and is_infinite
            {3'd0, ZERO,      INFINITE,  1'b?, 1'b?},
            {3'd0, INFINITE,  ZERO,      1'b?, 1'b?},
            {3'd0, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {3'd0, INFINITE,  SUBNORMAL, 1'b?, 1'b?},
            {3'd1, ZERO,      INFINITE,  1'b?, 1'b?},
            {3'd1, INFINITE,  ZERO,      1'b?, 1'b?},
            {3'd1, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {3'd1, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // add, sub: +/- infinity

            {3'd2, ZERO,      INFINITE,  1'b?, 1'b?},
            {3'd2, INFINITE,  ZERO,      1'b?, 1'b?},
            {3'd2, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {3'd2, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // mul: (zero * infinity) = quiet not a number

            {3'd3, ZERO,      INFINITE,  1'b?, 1'b?},
            {3'd3, SUBNORMAL, INFINITE,  1'b?, 1'b?}: result = {result_sign,       8'd0,                  1'b0,                 22'd0};                  // div: +/- zero
            {3'd3, INFINITE,  ZERO,      1'b?, 1'b?},
            {3'd3, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: result = {result_sign,       8'd255,                1'b0,                 22'd0};                  // div: +/- infinity

            // 8'b0?1????? // is_nan, is_nnan must be zero but doesn't care about anything else.
            {3'd0, NAN,       NAN,       1'b0, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  quiet not a number (following x86 standards)
            {3'd0, NORMAL,    NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // add:  quiet not a number (following x86 standards)
            {3'd0, NAN,       NORMAL,    1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  quiet not a number (following x86 standards)
            {3'd0, ZERO,      NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // add:  quiet not a number (following x86 standards)
            {3'd0, NAN,       ZERO,      1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  quiet not a number (following x86 standards)
            {3'd0, INFINITE,  NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // add:  quiet not a number (following x86 standards)
            {3'd0, NAN,       INFINITE,  1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  quiet not a number (following x86 standards)
            {3'd0, SUBNORMAL, NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // add:  quiet not a number (following x86 standards)
            {3'd0, NAN,       SUBNORMAL, 1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  quiet not a number (following x86 standards)

            {3'd1, NAN,       NAN,       1'b0, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NORMAL,    NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NAN,       NORMAL,    1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  quiet not a number (following x86 standards)
            {3'd1, ZERO,      NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NAN,       ZERO,      1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  quiet not a number (following x86 standards)
            {3'd1, INFINITE,  NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NAN,       INFINITE,  1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  quiet not a number (following x86 standards)
            {3'd1, SUBNORMAL, NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NAN,       SUBNORMAL, 1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  quiet not a number (following x86 standards)

            {3'd2, NAN,       NAN,       1'b0, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NORMAL,    NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NAN,       NORMAL,    1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  quiet not a number (following x86 standards)
            {3'd2, ZERO,      NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NAN,       ZERO,      1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  quiet not a number (following x86 standards)
            {3'd2, INFINITE,  NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NAN,       INFINITE,  1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  quiet not a number (following x86 standards)
            {3'd2, SUBNORMAL, NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NAN,       SUBNORMAL, 1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  quiet not a number (following x86 standards)

            {3'd3, NAN,       NAN,       1'b0, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  quiet not a number (following x86 standards)
            {3'd3, NORMAL,    NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // div:  quiet not a number (following x86 standards)
            {3'd3, NAN,       NORMAL,    1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  quiet not a number (following x86 standards)
            {3'd3, ZERO,      NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // div:  quiet not a number (following x86 standards)
            {3'd3, NAN,       ZERO,      1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  quiet not a number (following x86 standards)
            {3'd3, INFINITE,  NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // div:  quiet not a number (following x86 standards)
            {3'd3, NAN,       INFINITE,  1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  quiet not a number (following x86 standards)
            {3'd3, SUBNORMAL, NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // div:  quiet not a number (following x86 standards)
            {3'd3, NAN,       SUBNORMAL, 1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  quiet not a number (following x86 standards)

            {3'd4, DONTCARE,  NAN,       1'b?, 1'b0}: result = {1'b0,              8'd255,                1'b1,                 fraction_b[21:0]};       // sqrt: quiet not a number (following x86 standards)

            // 8'b1?0????? // is_nnan, is_nan must be zero but doesn't care about anything else.
            {3'd0, NAN,       NAN,       1'b1, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NORMAL,    NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NAN,       NORMAL,    1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, ZERO,      NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NAN,       ZERO,      1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, INFINITE,  NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NAN,       INFINITE,  1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, SUBNORMAL, NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NAN,       SUBNORMAL, 1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // add:  negative quiet not a number (following x86 standards)

            {3'd1, NAN,       NAN,       1'b1, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NORMAL,    NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NAN,       NORMAL,    1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, ZERO,      NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NAN,       ZERO,      1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, INFINITE,  NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NAN,       INFINITE,  1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, SUBNORMAL, NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NAN,       SUBNORMAL, 1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // sub:  negative quiet not a number (following x86 standards)

            {3'd2, NAN,       NAN,       1'b1, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NORMAL,    NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NAN,       NORMAL,    1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, ZERO,      NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NAN,       ZERO,      1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, INFINITE,  NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NAN,       INFINITE,  1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, SUBNORMAL, NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NAN,       SUBNORMAL, 1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // mul:  negative quiet not a number (following x86 standards)

            {3'd3, NAN,       NAN,       1'b1, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NORMAL,    NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NAN,       NORMAL,    1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, ZERO,      NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NAN,       ZERO,      1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, INFINITE,  NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NAN,       INFINITE,  1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, SUBNORMAL, NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NAN,       SUBNORMAL, 1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // div:  negative quiet not a number (following x86 standards)

            {3'd4, DONTCARE,  NAN,       1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 fraction_b[21:0]};       // sqrt: negative quiet not a number (following x86 standards)

            // normal results
            {3'd0, NORMAL,    NORMAL,    1'b?, 1'b?}: result = {result_sign,       result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // add: normal result
            {3'd1, NORMAL,    NORMAL,    1'b?, 1'b?}: result = {result_sign,       result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // sub: normal result
            {3'd2, NORMAL,    NORMAL,    1'b?, 1'b?}: result = {result_sign,       result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // mult: normal result
            {3'd3, NORMAL,    NORMAL,    1'b?, 1'b?}: result = {result_sign,       result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // div: normal result
            {3'd4, DONTCARE,  NORMAL,    1'b?, 1'b0}: result = {1'b0,              result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // sqrt: sign_a == 0 then normal result
            {3'd4, DONTCARE,  NORMAL,    1'b?, 1'b1}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // sqrt: sign_a == 1 then -1.#IND

            default:                                  result = {1'b0,              8'd0,                  1'b0,                 22'd0};                  // zero
        endcase
    end


    control_logic
    control_logic(
        .op,
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
        .operand_type_a,
        .operand_type_b,
        .exchange_operands,
        .align_shift_count,
        .post_sign
    );


    operand_exchanger
    operand_exchanger(
        .exchange_operands,
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
        .sorted_fraction_b
    );


    right_shifter
    right_shifter(
        .shift_count    (align_shift_count),
        .operand        (sorted_fraction_b),
        .result         (right_shifter_result)
    );


    leading_zeros_detector
    leading_zeros_detector(
        .value          (calculated_fraction[47:24]), // shouldn't this be 26-bits at the very least?
        .zeros          (normalize_shift_count)
    );


    left_shifter
    left_shifter(
        .shift_count    (normalize_shift_count),
        .operand        (calculated_fraction),
        .result         (left_shifter_result)
    );


    rounding_logic
    rounding_logic(
        .op,
        .normalized_exponent,
        .normalized_fraction,
        .remainder,
        .post_exponent,
        .post_fraction
    );


    multi_norm_combined #(.INWIDTH(25), .OUTWIDTH(26))
    multi_norm_combined(
        .clk,
        .reset,
        .mode                   (op == 3'd4),
        .start                  ((op == 3'd3 | op == 3'd4) & start),
        .dividend_in            ({sorted_fraction_a, 1'b0}),
        .divisor_radicand_in    (aligned_fraction_b[47:23]),
        .busy,
        .done,
        .quotient_root,
        .remainder
    );


endmodule

