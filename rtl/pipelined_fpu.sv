
// rounding modes
// round to zero (trucate)
// round to negative infinity
// round to positive infinity
// round to nearest even


// special cases
// exponent // fraction
//      = 0 //      = 0 // zero
//      = 0 //     != 0 // denormalized // implicit leading bit of fraction is set to 0 instead of 1, also the exponent is always -126
//    = 255 //      = 0 // +/- infinity
//    = 255 //     != 0 // NaN (not a number) // leading bit of stored fraction(bit 23) determines if this is quiet(nontrapping) or signaling(trapping)
                        // trapping NaNs trigger an exception when they are used as an operand in any operation, quiet NaNs don't trigger an exception.


// exception types are overflow, underflow, division-by-zero, invalid operation, and inexact result
// have an exception enable bit for each exception, also a seperate exception bit for each exception
// these bits stay set until they are cleared by an exception handler
// overflow happens when the exponent is greater than 254 or (126)
// underflow happens when the exponent is less than 1 or (-126)
// or if denormalized numbera are allowed underflow happens when the number
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
// a_nan:     0_11111111_01011110001011010110101
// bNaN:     0_11111111_00110110001010000001011
// expected: 0_11111111_11011110001011010110101

// a_nan:     0_11111111_00001101100100000001001
// bNaN:     0_11111111_11000010011011001101010
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


    logic          a_sign;
    logic  [7:0]   a_exponent;
    logic  [22:0]  a_fraction;


    logic          b_sign;
    logic  [7:0]   b_exponent;
    logic  [22:0]  b_fraction;


    logic          a_exponent_zeros;
    logic          a_exponent_ones;
    logic          a_fraction_zeros;


    logic          b_exponent_zeros;
    logic          b_exponent_ones;
    logic          b_fraction_zeros;


    //logic  [4:0]   a_leading_zeros;
    logic  [23:0]  a_norm_fraction;
    logic  [7:0]   a_norm_exponent;


    //logic  [4:0]   b_leading_zeros;
    logic  [23:0]  b_norm_fraction;
    logic  [7:0]   b_norm_exponent;


    logic          exponent_less;
    logic          exponent_equal;
    logic          fraction_less;
    logic          operand_swap;


    logic          sorted_sign_a;
    logic          sorted_sign_b;
    logic  [7:0]   sorted_exponent_a;
    logic  [7:0]   sorted_exponent_b;
    logic  [23:0]  sorted_fraction_a;
    logic  [23:0]  sorted_fraction_b;


    logic  [5:0]   equalized_shift_count;
    logic  [48:0]  equalized_fraction_b;


    logic  [24:0]  a_adj_fraction;
    logic  [25:0]  root;
    logic  [25:0]  quotient;
    logic  [26:0]  sqrt_rem;
    logic  [23:0]  div_rem;


    logic  [9:0]   imm_exponent;
    logic  [48:0]  imm_fraction;
    logic  [4:0]   imm_leading_zeros;


    logic  [9:0]   normalized_exponent;
    logic  [48:0]  normalized_fraction;
    

    //logic  [4:0]   denormalize_shift_count;
    //logic  [9:0]   denormalized_exponent;
    //logic  [47:0]  denormalized_fraction;


    logic  [9:0]   rounded_exponent;
    logic  [24:0]  rounded_fraction;


    logic  [9:0]   normalized_2_exponent;
    logic  [24:0]  normalized_2_fraction;


    logic          result_sign;


    logic          fraction_lsb;
    logic          guard_bit;
    logic          round_bit;
    logic          sticky_bit;


    // special case signals
    logic          a_zero;
    logic          b_zero;
    logic          abzero;
    logic          zero;
    logic          a_inf;
    logic          b_inf;
    logic          inf;
    logic          a_nan;
    logic          b_nan;
    logic          nan;
    logic          nnan;
    logic          signal;
    logic          a_denorm;
    logic          b_denorm;
    logic          denorm;
    logic          result_over;
    logic          result_denorm;
    logic          result_under;
    logic          result_zero;


    // busy and done signals
    logic          sqrt_busy;
    logic          sqrt_done;
    logic          div_busy;
    logic          div_done;


    always_comb begin
        // unpack fields
        a_sign           = a[31];
        a_exponent       = a[30:23];
        a_fraction       = a[22:0];

        b_sign           = b[31];
        b_exponent       = b[30:23];
        b_fraction       = b[22:0];


        // do checks on exponent and fraction
        a_exponent_zeros = ~|a_exponent;
        a_exponent_ones  =  &a_exponent;
        a_fraction_zeros = ~|a_fraction;

        b_exponent_zeros = ~|b_exponent;
        b_exponent_ones  =  &b_exponent;
        b_fraction_zeros = ~|b_fraction;


        // check for special cases
        a_zero   = a_exponent_zeros  & a_fraction_zeros;
        b_zero   = b_exponent_zeros  & b_fraction_zeros;
        a_inf    = a_exponent_ones   & a_fraction_zeros;
        b_inf    = b_exponent_ones   & b_fraction_zeros;
        a_nan    = a_exponent_ones   & ~a_fraction_zeros;
        b_nan    = b_exponent_ones   & ~b_fraction_zeros;
        a_denorm = a_exponent_zeros  & ~a_fraction_zeros;
        b_denorm = b_exponent_zeros  & ~b_fraction_zeros;

        if(op == 3'd4) begin            // for the single input square root function
            zero   = a_zero;
            inf    = a_inf;
            nan    = (~a_sign & a_nan);
            nnan   = (a_sign  & a_nan);
            signal = ~a_fraction[22];
            denorm = a_denorm;          // if we don't handle denormalized numbers then if this signal is active it could trigger an exception.
        end else begin                  // for everything else
            zero   = a_zero | b_zero;
            inf    = a_inf  | b_inf;
            nan    = (~a_sign & a_nan) | (~b_sign & b_nan);
            nnan   = (a_sign  & a_nan) | (b_sign  & b_nan);
            signal = ~a_fraction[22] | ~b_fraction[22];
            denorm = a_denorm | b_denorm; // if we don't handle denormalized numbers then if this signal is active it could trigger an exception.
        end


        // normalize operands
        a_norm_fraction = {1'b1, a_fraction};  // always set leading bit to 1, this is because we treat denormals as zero.
        b_norm_fraction = {1'b1, b_fraction};  // always set leading bit to 1, this is because we treat denormals as zero.
        a_norm_exponent = a_exponent;          // always set the exponent to the input value instead of 1 in the case of denormals.
        b_norm_exponent = b_exponent;          // always set the exponent to the input value instead of 1 in the case of denormals.


        // this is for the square root operation only
        // adjust operands // the exponent must be an even number because it has to be divided by 2 (this is to find the square root of the exponent), so we check if it's even and adjust it and the fraction if it's not.
        a_adj_fraction  = (a_norm_exponent[0]) ? {1'b0, a_norm_fraction} : {a_norm_fraction, 1'b0};    // if exponent is odd then right shift the fraction by one bit, else don't.


        // compare operands to see if we need to swap them
        exponent_less  = a_norm_exponent <  b_norm_exponent;
        exponent_equal = a_norm_exponent == b_norm_exponent;
        fraction_less  = a_norm_fraction <  b_norm_fraction;
        operand_swap   = exponent_less | (exponent_equal & fraction_less);


        // sort operands
        if(operand_swap) begin
            {sorted_sign_a, sorted_exponent_a, sorted_fraction_a} = {b_sign, b_norm_exponent, b_norm_fraction};
            {sorted_sign_b, sorted_exponent_b, sorted_fraction_b} = {a_sign, a_norm_exponent, a_norm_fraction};           
        end else begin
            {sorted_sign_a, sorted_exponent_a, sorted_fraction_a} = {a_sign, a_norm_exponent, a_norm_fraction};
            {sorted_sign_b, sorted_exponent_b, sorted_fraction_b} = {b_sign, b_norm_exponent, b_norm_fraction};
        end


        // equalize exponents
        equalized_shift_count = (sorted_exponent_a - sorted_exponent_b) <= 5'd26 ? sorted_exponent_a - sorted_exponent_b : 5'd31;
        equalized_fraction_b  = {1'd0, sorted_fraction_b, 24'd0} >> equalized_shift_count;


        // do calculation
        casex(op)
            3'd0:       begin
                            imm_exponent = sorted_exponent_a;
                            imm_fraction = (sorted_sign_a ^ sorted_sign_b) ? unsigned'({1'd0, sorted_fraction_a, 24'd0}) - unsigned'(equalized_fraction_b)
                                                                           : unsigned'({1'd0, sorted_fraction_a, 24'd0}) + unsigned'(equalized_fraction_b);
                        end

            3'd1:       begin
                            imm_exponent = sorted_exponent_a;
                            imm_fraction = (sorted_sign_a ~^ sorted_sign_b) ? unsigned'({1'd0, sorted_fraction_a, 24'd0}) - unsigned'(equalized_fraction_b)
                                                                            : unsigned'({1'd0, sorted_fraction_a, 24'd0}) + unsigned'(equalized_fraction_b);
                        end

            3'd2:       begin // for multiplication // add exponents and multiply fractions
                            imm_exponent = (unsigned'(a_norm_exponent) + unsigned'(b_norm_exponent)) - 10'd127;
                            imm_fraction = unsigned'(a_norm_fraction) * unsigned'(b_norm_fraction) << 1;
                        end

            3'd3:       begin // for division
                            imm_exponent = (unsigned'(a_norm_exponent) - unsigned'(b_norm_exponent)) + 10'd127;
                            imm_fraction = {1'b0, quotient, 22'd0}; // quotient is 26-bits wide
                        end

            default:    begin // for square root // find the sqrt of the fraction
                            imm_exponent = (a_norm_exponent[7:1] + 10'd63) + a_norm_exponent[0];  // this divides the exponent by 2, adds half the bias back in and if it was odd before increments the value by 1.
                            imm_fraction = {1'b0, root, 22'd0}; // root is 26-bits wide
                        end
        endcase


        // the sticky bit should be calculated here before normalization so that we
        // preserve the information from the last bit of the fraction before it is
        // right shifted and lost.


        // pre rounding normalization
        casex(imm_fraction[48:47])
            2'b1?:      begin // number overflowed right shift by 1
                            normalized_fraction = imm_fraction >> 1;
                            normalized_exponent = imm_exponent + 10'd1;
                        end
            2'b01:      begin // number already normalized
                            normalized_fraction = imm_fraction;
                            normalized_exponent = imm_exponent;
                        end
            default:    begin // number underflowed left shift, shifting by more than 1 is only required for addition and subtraction.
                            normalized_fraction = imm_fraction << imm_leading_zeros;
                            normalized_exponent = imm_exponent - imm_leading_zeros;
                        end
        endcase


        //denormalize_shift_count = (10'd1 - normalized_exponent) <= 5'd24 ? (10'd1 - normalized_exponent) : 5'd24;


        // denormalize value if exponent <= 0 and exponent >= -23 (not needed here)
        //if(normalized_exponent == 10'd0 || (normalized_exponent <= 10'd1023 && normalized_exponent >= 10'd1001)) begin
            //denormalized_fraction = normalized_fraction >> denormalize_shift_count;
            //denormalized_exponent = normalized_exponent +  denormalize_shift_count;
        //end else begin
            //denormalized_fraction = normalized_fraction;
            //denormalized_exponent = normalized_exponent;
        //end


        // result rounding
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


        // post rounding normalization
        normalized_2_fraction = (rounded_fraction[24]) ? rounded_fraction >> 1    : rounded_fraction;
        normalized_2_exponent = (rounded_fraction[24]) ? rounded_exponent + 10'd1 : rounded_exponent;


        // result sign calculation
        case(op)
            3'd0:       result_sign = sorted_sign_a;                                    // for add
            3'd1:       result_sign = (~operand_swap) ? sorted_sign_a : ~sorted_sign_a; // for sub
            default:    result_sign = a_sign ^ b_sign;                                  // for mul, div
        endcase


        // check for overflow, underflow, ect here
        result_over   = (normalized_2_exponent >=  10'd255 && normalized_2_exponent <=  10'd511);
        result_denorm = (normalized_2_exponent == 10'd0 || (normalized_2_exponent <=  -10'd1 && normalized_2_exponent >= -10'd23)); // ~normalized_2_fraction[23];
        result_under  = (normalized_2_exponent <= -10'd24  && normalized_2_exponent >= -10'd512);
        result_zero   = ~|normalized_2_fraction;


        // select final result and pack fields
        casex({nnan, result_denorm, nan, result_under, result_over, zero | denorm, inf, result_zero})
            8'b0?0??01?:    case(op)
                                3'd0:       begin
                                                case({a_inf, b_inf})
                                                    2'b01,
                                                    2'b10:      result = {result_sign, 8'd255, 23'b0};                           // add: +/- infinity
                                                    default:    if(sorted_sign_a != sorted_sign_b)
                                                                    result = {1'b1, 8'd255, 1'b1, 22'd0};                        // add: -1.#IND
                                                                else
                                                                    result = {result_sign, 8'd255, 23'b0};                       // add: +/- infinity
                                                endcase
                                            end
                                3'd1:       begin
                                                case({a_inf, b_inf})
                                                    2'b01,
                                                    2'b10:      result = {result_sign, 8'd255, 23'b0};                           // sub: +/- infinity
                                                    default:    if(sorted_sign_a == sorted_sign_b)
                                                                    result = {1'b1, 8'd255, 1'b1, 22'd0};                        // sub: -1.#IND
                                                                else
                                                                    result = {result_sign, 8'd255, 23'b0};                       // sub: +/- infinity
                                                endcase
                                            end
                                3'd3:       begin
                                                casex({a_inf, b_inf})
                                                    2'b10:      result = {result_sign, 8'd255, 23'b0};                           // div: +/- infinity
                                                    2'b01:      result = {result_sign, 8'd0,   23'b0};                           // div: +/- zero
                                                    default:    result = {1'b1, 8'd255, 1'b1, 22'd0};                            // div: -1.#IND
                                                endcase
                                            end
                                3'd4:       result = (a_sign) ? {1'b1, 8'd255, 1'b1, 22'd0}                                      // sqrt: if a_sign is 1 then -1.#IND
                                                              : {1'b0, 8'd255, 23'b0};                                           // sqrt: if a_sign is 0 then +infinity
                                default:    result = {result_sign, 8'd255, 23'b0};                                               // mul:  (num * infinity) = infinity
                            endcase
            8'b0?0??10?:    case(op)
                                3'd0:       begin
                                                casex({a_zero | a_denorm, b_zero | b_denorm})
                                                    2'b01:      result = {a_sign, a_exponent, a_fraction};                       // add: a
                                                    2'b10:      result = {b_sign, b_exponent, b_fraction};                       // add: b
                                                    default:    result = {a_sign & b_sign, 8'b0,  23'b0};                        // add: zero + zero = zero
                                                endcase
                                            end
                                3'd1:       begin
                                                casex({a_zero | a_denorm, b_zero | b_denorm})
                                                    2'b01:      result = {a_sign,  a_exponent, a_fraction};                      // sub: a
                                                    2'b10:      result = {~b_sign, b_exponent, b_fraction};                      // sub: b
                                                    default:    result = {a_sign & ~b_sign, 8'b0,  23'b0};                       // sub: zero + zero = zero
                                                endcase
                                            end
                                3'd3:       begin
                                                casex({a_zero | a_denorm, b_zero | b_denorm})
                                                    2'b01:      result = {result_sign, 8'd255, 23'd0};                           // div: +/- infinity
                                                    2'b11:      result = {1'b1, 8'd255, 1'b1, 22'd0};                            // div: -1.#IND
                                                    default:    result = {result_sign, 8'b0, 23'b0};                             // div: +/- zero
                                                endcase
                                            end
                                3'd4:       result = {a_sign,      8'b0, 23'b0};                                                 // sqrt: +/- zero
                                default:    result = {result_sign, 8'b0, 23'b0};                                                 // mul:  (num * zero) = zero
                            endcase
            8'b1?1?????:    result = {a_sign, 8'd255, 1'b1, a_fraction[21:0]};                                                   // (NaN * 1NaN)
            8'b0?0??11?:    case(op)
                                3'd0,
                                3'd1:       result = {result_sign, 8'd255, 23'd0};                                               // add, sub: +/- infinity
                                3'd3:       result = ((a_zero | a_denorm) & b_inf) ? {result_sign, 8'b0,   23'b0}                // div: +/- zero
                                                                      : {result_sign, 8'd255, 23'd0};                            // div: +/- infinity
                                default:    result = {1'b1, 8'd255, 23'b10000000000000000000000};                                // mul, sqrt: (zero * infinity) = quiet not a number
                            endcase
            8'b0?010000:    result = {result_sign, 8'd0,   23'b0};                                                               // underflow = zero
            8'b00001000:    result = {result_sign, 8'd255, 23'b0};                                                               // overflow = infinity
            8'b0?1?????:    case(op)
                                3'd4:       result = {1'b0, 8'd255, 1'b1, a_fraction[21:0]};                                     // sqrt: quiet not a number (following x86 standards)
                                default:    result = {1'b0, 8'd255, 1'b1, (a_nan) ? a_fraction[21:0] : b_fraction[21:0]};        // mul, div:  quiet not a number (following x86 standards)
                            endcase
            8'b1?0?????:    case(op)
                                3'd4:       result = {1'b1, 8'd255, 1'b1, a_fraction[21:0]};                                     // sqrt: negative quiet not a number (following x86 standards)
                                default:    result = {1'b1, 8'd255, 1'b1, (a_nan) ? a_fraction[21:0] : b_fraction[21:0]};        // add, sub, mul, div:  negative quiet not a number (following x86 standards)
                            endcase
            8'b01000000:    result = {result_sign, 8'd0, 23'b0};                                                                 // denormalized result (treat as zero)
            8'b0?000001:    result = {1'b0, 8'd0, 23'd0};                                                                        // add, sub only?: zero
            default:        case(op)
                                3'd4:       result = (a_sign) ? {1'b1, 8'd255, 1'b1, 22'd0}                                      // sqrt: a_sign == 1 then -1.#IND
                                                              : {1'b0, normalized_2_exponent[7:0], normalized_2_fraction[22:0]}; // sqrt: a_sign == 0 then normal result
                                default:    result = {result_sign, normalized_2_exponent[7:0], normalized_2_fraction[22:0]};     // add, sub, mult, div: normal result
                            endcase
        endcase
    end


    leading_zeros_detector
    leading_zeros_detector(
        .value         (imm_fraction[47:24]), // shouldn't this be 26-bits at the very least?
        .zeros         (imm_leading_zeros)
    );


    multi_norm_divider #(.INWIDTH(24), .OUTWIDTH(26))
    multi_norm_divider(
        .clk,
        .reset,
        .start         (op == 3'd3 & start),
        .dividend_in   (a_norm_fraction),
        .divisor_in    (b_norm_fraction),
        .busy          (sqrt_busy),
        .done          (sqrt_done),
        .quotient      (quotient),
        .remainder     (div_rem)
    );


    multi_norm_sqrt #(.INWIDTH(25), .OUTWIDTH(26))
    multi_norm_sqrt(
        .clk,
        .reset,
        .start         (op == 3'd4 & start),
        .radicand_in   (a_adj_fraction),
        .busy          (div_busy),
        .done          (div_done),
        .root          (root),
        .remainder     (sqrt_rem)
    );


    assign busy = sqrt_busy | div_busy;
    assign done = sqrt_done | div_done;


endmodule

