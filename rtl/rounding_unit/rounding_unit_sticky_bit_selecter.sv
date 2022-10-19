

module rounding_unit_sticky_bit_selecter(
    input   logic  [1:0]   sticky_bit_select,
    input   logic  [48:0]  normalized_fraction,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic  [26:0]  remainder,

    output  logic          sticky_bit
    );


    always_comb begin
        casex(sticky_bit_select)
            2'd0:    sticky_bit = |normalized_fraction[21:0]; // for add, sub, and mul.
            2'd1:    sticky_bit = |remainder;                 // for div and sqrt
            default: sticky_bit = |normalized_fraction[14:0]; // for float to in rounding
        endcase
    end


endmodule

