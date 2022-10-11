

module rounding_unit_fraction_incrementer(
    input   logic  [48:0]  normalized_fraction,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic  [24:0]  incremented_fraction  // is [xx.xxxx...] format with 2 integer bits, 23 fractional bits
    );


    assign incremented_fraction = normalized_fraction[47:24] + 24'd1;


endmodule

