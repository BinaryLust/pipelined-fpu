

module rounding_unit_sticky_bit_selecter(
    input   logic          sticky_bit_select,
    input   logic  [48:0]  normalized_fraction,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic  [26:0]  remainder,

    output  logic          sticky_bit
    );


    assign sticky_bit = (sticky_bit_select) ? |remainder : |normalized_fraction[21:0];


endmodule

