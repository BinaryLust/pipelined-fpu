

module rounding_unit_fraction_selecter(
    input   logic          rounding_mode,
    input   logic          sticky_bit,
    input   logic  [48:0]  normalized_fraction,   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic  [31:0]  incremented_fraction,  // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits

    output  logic  [31:0]  rounded_fraction       // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits
    );


    logic  fraction_lsb;
    logic  guard_bit;
    logic  round_bit;


    always_comb begin
        fraction_lsb = (rounding_mode) ? normalized_fraction[17] : normalized_fraction[24]; // the least significant bit of the fraction, it is used for rounding to the nearest even
        guard_bit    = (rounding_mode) ? normalized_fraction[16] : normalized_fraction[23];
        round_bit    = (rounding_mode) ? normalized_fraction[15] : normalized_fraction[22];

        casex({fraction_lsb, guard_bit, round_bit, sticky_bit})
            4'b?000,
            4'b?001,
            4'b?010,
            4'b?011,
            4'b0100: rounded_fraction = normalized_fraction[48:17];
            4'b1100,
            4'b?101,
            4'b?110,
            4'b?111: rounded_fraction = incremented_fraction;
        endcase
    end


endmodule

