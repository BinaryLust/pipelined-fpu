

module rounding_logic(
    input   logic  [2:0]   op,
    input   logic  [9:0]   normalized_exponent,
    input   logic  [48:0]  normalized_fraction,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic  [26:0]  remainder,

    output  logic  [9:0]   post_exponent,
    output  logic  [24:0]  post_fraction         // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits
    );


    logic          fraction_lsb;
    logic          guard_bit;
    logic          round_bit;
    logic          sticky_bit;
    logic  [9:0]   rounded_exponent;
    logic  [24:0]  rounded_fraction;  // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits


    always_comb begin
        fraction_lsb = normalized_fraction[24]; // the least significant bit of the fraction, it is used for rounding to the nearest even
        guard_bit    = normalized_fraction[23];
        round_bit    = normalized_fraction[22];
        casex(op)
            3'd3,
            3'd4:    sticky_bit = |remainder;
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
    end


endmodule

