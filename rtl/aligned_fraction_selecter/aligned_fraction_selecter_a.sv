

module aligned_fraction_selecter_a(
    input   logic          aligned_fraction_a_select,
    input   logic  [23:0]  aligned_fraction_a_in,   // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits

    output  logic  [23:0]  aligned_fraction_a_out   // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    );


    assign aligned_fraction_a_out = (aligned_fraction_a_select) ? 24'd0 : aligned_fraction_a_in;


endmodule

