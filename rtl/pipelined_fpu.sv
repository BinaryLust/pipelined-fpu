
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
    input   logic          start,
    input   logic  [31:0]  a,

    output  logic          done,
    output  logic          busy,
    output  logic  [31:0]  result
    );


    logic          a_sign;
    logic  [7:0]   a_exponent;
    logic  [22:0]  a_fraction;


    logic          a_exponent_zeros;
    logic          a_exponent_ones;
    logic          a_fraction_zeros;


    logic  [4:0]   a_leading_zeros;
    logic  [23:0]  a_norm_fraction;
    logic  [9:0]   a_norm_exponent;


    logic  [24:0]  a_adj_fraction;
    logic  [9:0]   a_adj_exponent;
    logic  [46:0]  fract_sqrt;


    logic  [9:0]   imm_exponent;
    logic  [47:0]  imm_fraction;


    logic  [9:0]   normalized_exponent;
    logic  [47:0]  normalized_fraction;
    

    logic  [4:0]   denormalize_shift_count;
    logic  [9:0]   denormalized_exponent;
    logic  [47:0]  denormalized_fraction;


    logic  [9:0]   rounded_exponent;
    logic  [24:0]  rounded_fraction;


    logic  [9:0]   normalized_2_exponent;
    logic  [24:0]  normalized_2_fraction;


    logic          fraction_lsb;
    logic          round_bit;
    logic          sticky_bit;


    // special case signals
    logic          a_zero;
    logic          zero;
    logic          a_inf;
    logic          inf;
    logic          a_nan;
    logic          nan;
    logic          nnan;
    logic          signal;
    logic          a_denorm;
    logic          denorm;
    logic          result_over;
    logic          result_denorm;
    logic          result_under;


    // test signal remove later
    logic          test;


    always_comb begin
       // unpack fields
       a_sign           = a[31];
       a_exponent       = a[30:23];
       a_fraction       = a[22:0];

       // do checks on exponent and fraction
       a_exponent_zeros = ~|a_exponent;
       a_exponent_ones  =  &a_exponent;
       a_fraction_zeros = ~|a_fraction;

       // check for special cases
       a_zero           = a_exponent_zeros  & a_fraction_zeros;
       zero             = a_zero;

       a_inf            = a_exponent_ones   & a_fraction_zeros;
       inf              = a_inf;

       a_nan            = a_exponent_ones   & ~a_fraction_zeros;
       nan              = (~a_sign & a_nan);
       nnan             = (a_sign  & a_nan);
       signal           = ~a_fraction[22];

       a_denorm         = a_exponent_zeros  & ~a_fraction_zeros;
       denorm           = a_denorm;            // if we don't handle denormalized numbers then if this signal is active it could trigger an exception.


       // normalize operands
       a_norm_fraction  = {1'b1, a_fraction};  // always set leading bit to 1, this is because we treat denormals as zero.
       a_norm_exponent  = a_exponent;          // always set the exponent to the input value instead of 1 in the case of denormals.

       // adjust operands // the exponent must be an even number because it has to be divided by 2 (this is to find the square root of the exponent), so we check if it's even and adjust it and the fraction if it's not.
       a_adj_fraction   = (a_norm_exponent[0]) ? {1'b0, a_norm_fraction} : {a_norm_fraction, 1'b0};    // if exponent is odd then right shift the fraction by one bit, else don't.
       a_adj_exponent   = ({a_norm_exponent[9], a_norm_exponent[9:1]} + 10'd63) + a_norm_exponent[0];  // this divides the exponent by 2, adds half the bias back in and if it was odd before increments the value by 1.

       // find the sqrt of the fraction
       imm_fraction     = {1'b0, fract_sqrt};
       imm_exponent     = a_adj_exponent;


       // the sticky bit should be calculated here before normalization so that we
       // preserve the information from the last bit of the fraction before it is
       // right shifted and lost.


       // pre rounding normalization (not needed here)
       //if(~imm_fraction[46]) begin // number needs to be normalized left shift by 1
           //normalized_fraction = imm_fraction << 1;
           //normalized_exponent = imm_exponent - 10'd1;
       //end else begin              // number already normalized
           normalized_fraction = imm_fraction;
           normalized_exponent = imm_exponent;
       //end


       //denormalize_shift_count = (10'd1 - normalized_exponent) <= 5'd24 ? (10'd1 - normalized_exponent) : 5'd24;


       // denormalize value if exponent <= 0 and exponent >= -23 (not needed here)
       //if(normalized_exponent == 10'd0 || (normalized_exponent <= 10'd1023 && normalized_exponent >= 10'd1001)) begin
           //denormalized_fraction = normalized_fraction >> denormalize_shift_count;
           //denormalized_exponent = normalized_exponent +  denormalize_shift_count;
       //end else begin
           denormalized_fraction = normalized_fraction;
           denormalized_exponent = normalized_exponent;
       //end


       // result rounding
       fraction_lsb        = denormalized_fraction[23]; // the least significant bit of the fraction, it is used for rounding to the nearest even
       round_bit           = denormalized_fraction[22];
       sticky_bit          = |denormalized_fraction[21:0];

       rounded_exponent    = denormalized_exponent;

       casex({fraction_lsb, round_bit, sticky_bit})
           3'b?00,
           3'b?01,
           3'b010: rounded_fraction = {1'b0, denormalized_fraction[46:23]};
           
           3'b110,
           3'b?11: rounded_fraction = denormalized_fraction[46:23] + 24'd1;
       endcase

       // post rounding normalization
       normalized_2_fraction = (rounded_fraction[24]) ? rounded_fraction >> 1    : rounded_fraction;
       normalized_2_exponent = (rounded_fraction[24]) ? rounded_exponent + 10'd1 : rounded_exponent;

       // check for overflow, underflow, ect here
       result_over   = (normalized_2_exponent >=  10'd255 && normalized_2_exponent <=  10'd511);
       result_denorm = ~normalized_2_fraction[23];
       result_under  = (normalized_2_exponent <= -10'd24  && normalized_2_exponent >= -10'd512);


       // testing signal
       test = result_denorm & done;


       // select final result and pack fields
       casex({nnan, result_denorm, nan, result_under, result_over, zero|denorm, inf})
           7'b0?0??01: begin
                           if(a_sign)
                               result = {1'b1, 8'd255, 1'b1, 22'd0};                                 // -1.#IND
                           else
                               result = {1'b0, 8'd255, 23'b0};                                       // +infinity
                       end
           7'b0?0??10: result = {a_sign, 8'b0,   23'b0};                                              // +/- zero

           // the result can never overflow, underflow or be denormalized so I removed those conditions here

           7'b0?1????: result = {1'b0, 8'd255, 1'b1, a_fraction[21:0]};                               // NaN
           7'b1?0????: result = {1'b1, 8'd255, 1'b1, a_fraction[21:0]};                               // negative quiet not a number (following x86 standards)
           default:    begin
                           if(a_sign)
                               result = {1'b1, 8'd255, 1'b1, 22'd0}; // -1.#IND
                           else
                               result = {1'b0, normalized_2_exponent[7:0], normalized_2_fraction[22:0]}; // normal result
                       end
       endcase
    end


    multi_norm_sqrt #(.INWIDTH(25), .OUTWIDTH(47))
    multi_norm_sqrt(
        .clk,
        .reset,
        .start,
        .radicand_in    (a_adj_fraction),
        .busy,
        .done,
        .root          (fract_sqrt),
        .remainder     ()
    );


endmodule

