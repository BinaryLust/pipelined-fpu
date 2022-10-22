

module aligned_exponent_selecter_b(
    input   logic          aligned_exponent_b_select,
    input   logic  [7:0]   aligned_exponent_b,

    output  logic  [7:0]   aligned_exponent_b_out
    );


    assign aligned_exponent_b_out = (aligned_exponent_b_select) ? 8'd30 : aligned_exponent_b;


endmodule

