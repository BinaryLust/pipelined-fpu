

module calculation_unit_fraction_adder(
    input   logic                            [23:0]  aligned_fraction_a,  // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    input   logic                            [48:0]  aligned_fraction_b,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic                            [48:0]  fraction_adder       // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    assign fraction_adder = unsigned'({1'd0, aligned_fraction_a, 24'd0}) + unsigned'(aligned_fraction_b);


endmodule

