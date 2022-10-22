

module exponent_bias_remover(
    input   logic          remove_bias,
    input   logic  [7:0]   operand_exponent_a,
    input   logic  [7:0]   operand_exponent_b,

    output  logic  [7:0]   unbiased_exponent_a,
    output  logic  [7:0]   unbiased_exponent_b
    );


    assign unbiased_exponent_a = (remove_bias) ? operand_exponent_a - 8'd127 : operand_exponent_a;
    assign unbiased_exponent_b = (remove_bias) ? operand_exponent_b - 8'd127 : operand_exponent_b;


endmodule

