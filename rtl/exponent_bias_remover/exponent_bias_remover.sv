

module exponent_bias_remover(
    input   logic  [7:0]   operand_exponent_a,
    input   logic  [7:0]   operand_exponent_b,

    output  logic  [7:0]   unbiased_exponent_a,
    output  logic  [7:0]   unbiased_exponent_b
    );


    assign unbiased_exponent_a = operand_exponent_a - 8'd127;
    assign unbiased_exponent_b = operand_exponent_b - 8'd127;


endmodule

