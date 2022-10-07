
// rounding modes
// round to zero (trucate)
// round to negative infinity
// round to positive infinity
// round to nearest even


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


// rounding bits for round to nearest
// guard(LSB) = bit[22]
// round(R)   = bit[21]
// sticky(S)  = bits[20:0]


// round to nearest even logic table
// round bit is sub fraction bit 24, sticky bit is the or of all bits from 23 to 0 of the sub fraction
// fraction[0] // round bit // sticky bit
//           x            0             0 // number is < 1/2 // round down by keeping the fraction the same
//           x            0             1 // number is < 1/2 // round down by keeping the fraction the same
//           0            1             0 // number is 1/2   // round down by keeping the fraction the same
//           1            1             0 // number is 1/2   // round up by adding 1 to the fraction
//           x            1             1 // number is > 1/2 // round up by adding 1 to the fraction

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


// for division we subtract the exponents and add the bias back in so (e1 - e2) + 127
// we also need to divide the fractions so (f1 / f2)

// floating point remainder is defined as f1 - f2 * int(f1 / f2)
// I think it is basically returning the fractional part of the number
// like in the case of 10.756 it would be 0.756
// https://www.geeksforgeeks.org/modulus-two-float-double-numbers/
// that site defines it as what is left over from the dividend after we subtract
// the divisor from it a integer number of times.

// for subtraction they are figuring out rounding before they actually do the subtraction
// so

// qNaN doesn't signal an exception and just flows through calucations, all operations
// which generate NaN's are supposed to generate qNaN's except when a sNaN is used
// as one of the operands. its value is (.1u...u)

// sNaN is typically the value set to uninitialized floating point values so that they
// will singal an exception if that value is used in a calculation, its value is(.0u...u)

// multiplication special cases
//  normal *  0   =  0
// -normal *  0   = -0
// +inf    *  0   =  qNaN
// -inf    *  0   = -qNaN // this result is odd.
//  NaN    *  0   =  qNaN
//  normal * -inf = -inf
//  normal * +inf = +inf
// -normal * -inf = +inf
// -normal * +inf = -inf
// +inf    * -inf = -inf
// +inf    * +inf = +inf
//  normal *  NaN =  qNaN
// -normal *  NaN =  qNaN
// +inf    *  NaN =  qNaN
// -inf    *  NaN =  qNaN

// bits needed for rounding
// addition:    needs fraction + round bit + sticky bit
// subtraction: needs fraction + guard bit + round bit + sticky bit


// x86 floating point expection when returning a NaN from 2 NaN inputs
// is_nan_a: 0_11111111_01011110001011010110101
// is_nan_b: 0_11111111_00110110001010000001011
// expected: 0_11111111_11011110001011010110101

// is_nan_a: 0_11111111_00001101100100000001001
// is_nan_b  0_11111111_11000010011011001101010
// expected: 0_11111111_10001101100100000001001


// we could choose to just turn subnormal values into zeros if we don't want to support them, or trigger an
// interrupt each time one is seen.


// to allow this to divide subnormal numbers properly we have a few options
//
// we could normalize subnormal operands before doing division on them, but this would take 2 32 bit left shifters
//
// we could use a right shifter and a 2nd leading zero/leading one counter to right shift the result after division
// the reason for this is when dividing a large number by a small subnormal number the result can be larger than
// the standard 47/48 bits in which case it needs to be corrected.
//


// an example of finding square roots
// we start off with
// fraction = 1.25  (1.010)
// exponent = 2 ^ 9 (1001)

// we assume that all of the numbers input will be normalized.
// first we must adjust the fraction and exponent, the fraction must be in the format of 0.1... or 0.01...
// and the exponent must be an even number also. if the exponent is odd we right shift the fraction by one
// and increment the exponent by 1, if the exponent is even we must right shift the exponent by 2 and
// increment the exponent by 2.
// fraction = 0.625  (0.101)
// exponent = 2 ^ 10 (1010)

// next we calculate the sqrt of the fraction and exponent. the sqrt of the exponent is calculated by simply
// right shifting by 1, the sqrt of the fraction must be calculated in a full blown sqrt calculator.
// fraction = 0.8125 (0.1101)
// exponent = 2 ^ 5  (0101)

// next we normalized the result
// fraction = 1.625  (1.101)
// exponent = 2 ^ 4  (0100)

// next we would round the result and normalize again but that part is skipped here


// for biased exponents we will have to do (exponent[9:1] + 9'd63) + exponent[0]
// when dividing by 2 to find the sqrt of it.

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


    typedef  enum  logic  [2:0]
    {
        NORMAL    = 3'b00?,
        ZERO      = 3'b101,
        INFINITE  = 3'b011,
        NAN       = 3'b010,
        SUBNORMAL = 3'b100,
        DONTCARE  = 3'b???
    }   operand_types;


    logic          sign_a;
    logic  [7:0]   exponent_a;
    logic  [22:0]  fraction_a;


    logic          sign_b;
    logic  [7:0]   exponent_b;
    logic  [22:0]  fraction_b;


    logic          exponent_all_zeros_a;
    logic          exponent_all_ones_a;
    logic          fraction_all_zeros_a;


    logic          exponent_all_zeros_b;
    logic          exponent_all_ones_b;
    logic          fraction_all_zeros_b;


    operand_types  operand_type_a;
    operand_types  operand_type_b;


    logic          exponent_less;
    logic          exponent_equal;
    logic          fraction_less;
    logic          exchange_operands;


    logic          sorted_sign_a;
    logic          sorted_sign_b;
    logic  [7:0]   sorted_exponent_a;
    logic  [7:0]   sorted_exponent_b;
    logic  [23:0]  sorted_fraction_a;      // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    logic  [23:0]  sorted_fraction_b;      // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits


    logic  [47:0]  right_shifter_result;


    logic          align_shift_count_a;
    logic  [4:0]   align_shift_count_b;
    logic  [24:0]  aligned_fraction_a;     // is [x.xxxx....] format with 1 integer bit,  24 fractional bits
    logic  [48:0]  aligned_fraction_b;     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits


    logic  [25:0]  root;                   // is [x.xxxx...]  format with 1 integer bits  25 fractional bits
    logic  [25:0]  quotient;               // is [x.xxxx...]  format with 1 integer bit,  25 fractional bits
    logic  [26:0]  sqrt_rem;
    logic  [23:0]  div_rem;


    logic  [9:0]   calculated_exponent;
    logic  [48:0]  calculated_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits


    logic  [48:0]  left_shifter_result;


    logic  [9:0]   normalized_exponent;
    logic  [48:0]  normalized_fraction;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    logic  [4:0]   normalize_shift_count;    


    logic          fraction_lsb;
    logic          guard_bit;
    logic          round_bit;
    logic          sticky_bit;


    logic  [9:0]   rounded_exponent;
    logic  [24:0]  rounded_fraction;       // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits


    logic          post_sign;
    logic  [9:0]   post_exponent;
    logic  [24:0]  post_fraction;          // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits


    logic          result_sign;
    logic  [9:0]   result_exponent;
    logic  [24:0]  result_fraction;        // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits


    // busy and done signals
    logic          sqrt_busy;
    logic          sqrt_done;
    logic          div_busy;
    logic          div_done;


    always_comb begin
        // unpack fields
        sign_a           = a[31];
        exponent_a       = a[30:23];
        fraction_a       = a[22:0];

        sign_b           = b[31];
        exponent_b       = b[30:23];
        fraction_b       = b[22:0];


        // do checks on exponent and fraction
        exponent_all_zeros_a = ~|exponent_a;
        exponent_all_ones_a  =  &exponent_a;
        fraction_all_zeros_a = ~|fraction_a;

        exponent_all_zeros_b = ~|exponent_b;
        exponent_all_ones_b  =  &exponent_b;
        fraction_all_zeros_b = ~|fraction_b;


        // form the bits for the type of each operand
        operand_type_a = operand_types'({exponent_all_zeros_a, exponent_all_ones_a, fraction_all_zeros_a});
        operand_type_b = operand_types'({exponent_all_zeros_b, exponent_all_ones_b, fraction_all_zeros_b});


        // compare operands to see if we need to exchange them.
        exponent_less     = exponent_a <  exponent_b;
        exponent_equal    = exponent_a == exponent_b;
        fraction_less     = fraction_a < fraction_b;
        exchange_operands = ((op == 3'd0) | (op == 3'd1)) & (exponent_less | (exponent_equal & fraction_less));


        // sort operands, also add leading 1 bit to fraction. the leading bit will always be 1 because we treat subnormals as zero here.
        // we will only do this for addition and subtraction operations, for all other operations we just pass the values through.
        if(exchange_operands) begin
            {sorted_sign_a, sorted_exponent_a, sorted_fraction_a} = {sign_b, exponent_b, 1'b1, fraction_b};
            {sorted_sign_b, sorted_exponent_b, sorted_fraction_b} = {sign_a, exponent_a, 1'b1, fraction_a};           
        end else begin
            {sorted_sign_a, sorted_exponent_a, sorted_fraction_a} = {sign_a, exponent_a, 1'b1, fraction_a};
            {sorted_sign_b, sorted_exponent_b, sorted_fraction_b} = {sign_b, exponent_b, 1'b1, fraction_b};
        end


        // do alignment
        align_shift_count_a = (op == 3'd4) & exponent_a[0];  // this is for the square root operation only. the exponent must be an even number because it has to be divided by 2 (this is to find the square root of the exponent), so we check if it's even and adjust it and the fraction if it's not.
        align_shift_count_b = ((op == 3'd0) | (op == 3'd1)) ? ((sorted_exponent_a - sorted_exponent_b) <= 5'd26) ? sorted_exponent_a - sorted_exponent_b : 5'd31 : 5'd0;; // this is for addition and subtraction operations only.
        aligned_fraction_a  = (align_shift_count_a) ? {1'b0, sorted_fraction_a} : {sorted_fraction_a, 1'b0};                                                              // if exponent is odd then right shift the fraction by one bit, else don't.
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
                            calculated_fraction = (unsigned'(aligned_fraction_a[24:1]) * unsigned'(aligned_fraction_b[47:24])) << 1;
                        end

            3'd3:       begin // for division
                            calculated_exponent = (unsigned'(sorted_exponent_a) - unsigned'(sorted_exponent_b)) + 10'd127;
                            calculated_fraction = {1'b0, quotient, 22'd0}; // quotient is 26-bits wide
                        end

            default:    begin // for square root // find the sqrt of the fraction
                            calculated_exponent = (sorted_exponent_a[7:1] + 10'd63) + sorted_exponent_a[0];  // this divides the exponent by 2, adds half the bias back in and if it was odd before increments the value by 1.
                            calculated_fraction = {1'b0, root, 22'd0}; // root is 26-bits wide
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
        fraction_lsb = normalized_fraction[24]; // the least significant bit of the fraction, it is used for rounding to the nearest even
        guard_bit    = normalized_fraction[23];
        round_bit    = normalized_fraction[22];
        casex(op)
            3'd3:    sticky_bit = |div_rem;
            3'd4:    sticky_bit = |sqrt_rem;
            default: sticky_bit = |normalized_fraction[21:0];
        endcase

        rounded_exponent = normalized_exponent;

        casex({fraction_lsb, guard_bit, round_bit, sticky_bit})
            4'b?000,
            4'b?001,
            4'b?010,
            4'b?011,
            4'b0100: rounded_fraction = {1'b0, normalized_fraction[47:24]};

            4'b1100,
            4'b?101,
            4'b?110,
            4'b?111: rounded_fraction = normalized_fraction[47:24] + 24'd1;
        endcase

        // we might be able to do rounding and post rounding normalization in a single step?
        // the only condition it will happen is when all the bits are one before we add one to it


        // do post rounding normalization
        post_fraction = (rounded_fraction[24]) ? rounded_fraction >> 1    : rounded_fraction;
        post_exponent = (rounded_fraction[24]) ? rounded_exponent + 10'd1 : rounded_exponent;


        // sign calculation
        case(op)
            3'd0:    post_sign = sorted_sign_a;                                         // for add
            3'd1:    post_sign = (~exchange_operands) ? sorted_sign_a : ~sorted_sign_a; // for sub
            default: post_sign = sign_a ^ sign_b;                                       // for mul, div
        endcase


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

            {3'd4, INFINITE,  DONTCARE,  1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // sqrt: if sign_a is 1 then -1.#IND
            {3'd4, INFINITE,  DONTCARE,  1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b0,                 22'd0};                  // sqrt: if sign_a is 0 then +infinity

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

            {3'd4, ZERO,      DONTCARE,  1'b?, 1'b?},
            {3'd4, SUBNORMAL, DONTCARE,  1'b?, 1'b?}: result = {sign_a,            8'd0,                  1'b0,                 22'd0};                  // sqrt: +/- zero

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

            {3'd4, NAN,       DONTCARE,  1'b0, 1'b?}: result = {1'b0,              8'd255,                1'b1,                 fraction_a[21:0]};       // sqrt: quiet not a number (following x86 standards)

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

            {3'd4, NAN,       DONTCARE,  1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 fraction_a[21:0]};       // sqrt: negative quiet not a number (following x86 standards)

            // normal results
            {3'd0, NORMAL,    NORMAL,    1'b?, 1'b?}: result = {result_sign,       result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // add: normal result
            {3'd1, NORMAL,    NORMAL,    1'b?, 1'b?}: result = {result_sign,       result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // sub: normal result
            {3'd2, NORMAL,    NORMAL,    1'b?, 1'b?}: result = {result_sign,       result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // mult: normal result
            {3'd3, NORMAL,    NORMAL,    1'b?, 1'b?}: result = {result_sign,       result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // div: normal result
            {3'd4, NORMAL,    DONTCARE,  1'b0, 1'b?}: result = {1'b0,              result_exponent[7:0],  result_fraction[22],  result_fraction[21:0]};  // sqrt: sign_a == 0 then normal result
            {3'd4, NORMAL,    DONTCARE,  1'b1, 1'b?}: result = {1'b1,              8'd255,                1'b1,                 22'd0};                  // sqrt: sign_a == 1 then -1.#IND

            default:                                  result = {1'b0,              8'd0,                  1'b0,                 22'd0};                  // zero
        endcase
    end


    right_shifter
    right_shifter(
        .shift_count    (align_shift_count_b),
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


    multi_norm_divider #(.INWIDTH(24), .OUTWIDTH(26))
    multi_norm_divider(
        .clk,
        .reset,
        .start          (op == 3'd3 & start),
        .dividend_in    (aligned_fraction_a[24:1]),
        .divisor_in     (aligned_fraction_b[47:24]),
        .busy           (sqrt_busy),
        .done           (sqrt_done),
        .quotient       (quotient),
        .remainder      (div_rem)
    );


    multi_norm_sqrt #(.INWIDTH(25), .OUTWIDTH(26))
    multi_norm_sqrt(
        .clk,
        .reset,
        .start          (op == 3'd4 & start),
        .radicand_in    (aligned_fraction_a),
        .busy           (div_busy),
        .done           (div_done),
        .root           (root),
        .remainder      (sqrt_rem)
    );


    assign busy = sqrt_busy | div_busy;
    assign done = sqrt_done | div_done;


endmodule

