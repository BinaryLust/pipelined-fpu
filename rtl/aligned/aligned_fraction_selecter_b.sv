

module aligned_fraction_selecter_b(
    input   logic          aligned_fraction_b_select,
    input   logic          aligned_sign_b,
    input   logic  [7:0]   aligned_exponent_b,
    input   logic  [48:0]  aligned_fraction_b,     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic  [48:0]  aligned_fraction_b_out  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    assign aligned_fraction_b_out = (aligned_fraction_b_select) ? {aligned_sign_b, aligned_exponent_b, aligned_fraction_b[46:24], 17'd0} : aligned_fraction_b;


endmodule

