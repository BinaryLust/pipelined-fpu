

module rounding_unit_fraction_selecter(
    input   logic          sticky_bit,
    input   logic  [48:0]  normalized_fraction,   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic  [24:0]  incremented_fraction,  // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits

    output  logic  [24:0]  rounded_fraction       // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits
    );


    logic  fraction_lsb;
    logic  guard_bit;
    logic  round_bit;


    always_comb begin
        fraction_lsb = normalized_fraction[24]; // the least significant bit of the fraction, it is used for rounding to the nearest even
        guard_bit    = normalized_fraction[23];
        round_bit    = normalized_fraction[22];

        casex({fraction_lsb, guard_bit, round_bit, sticky_bit})
            4'b?000,
            4'b?001,
            4'b?010,
            4'b?011,
            4'b0100: rounded_fraction = {1'b0, normalized_fraction[47:24]};
            4'b1100,
            4'b?101,
            4'b?110,
            4'b?111: rounded_fraction = incremented_fraction;
        endcase
    end


endmodule

