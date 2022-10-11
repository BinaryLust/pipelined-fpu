

module calculation_unit_fraction_multiplier(
    input   logic                            [23:0]  sorted_fraction_a,   // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    input   logic                            [48:0]  aligned_fraction_b,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic                            [48:0]  fraction_multiplier  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    assign fraction_multiplier = (unsigned'(sorted_fraction_a) * unsigned'(aligned_fraction_b[47:24])) << 1;


endmodule

