

module aligner_operand_exchanger(
    input   logic          exchange_operands,
    input   logic          operand_sign_a,
    input   logic  [7:0]   unbiased_exponent_a,
    input   logic  [23:0]  operand_fraction_a,
    input   logic          operand_sign_b,
    input   logic  [7:0]   unbiased_exponent_b,
    input   logic  [23:0]  operand_fraction_b,

    output  logic          sorted_sign_a,
    output  logic  [7:0]   sorted_exponent_a,
    output  logic  [23:0]  sorted_fraction_a,
    output  logic          sorted_sign_b,
    output  logic  [7:0]   sorted_exponent_b,
    output  logic  [23:0]  sorted_fraction_b
    );


    always_comb begin
        if(exchange_operands) begin
            {sorted_sign_a, sorted_exponent_a, sorted_fraction_a} = {operand_sign_b, unbiased_exponent_b, operand_fraction_b};
            {sorted_sign_b, sorted_exponent_b, sorted_fraction_b} = {operand_sign_a, unbiased_exponent_a, operand_fraction_a};           
        end else begin
            {sorted_sign_a, sorted_exponent_a, sorted_fraction_a} = {operand_sign_a, unbiased_exponent_a, operand_fraction_a};
            {sorted_sign_b, sorted_exponent_b, sorted_fraction_b} = {operand_sign_b, unbiased_exponent_b, operand_fraction_b};
        end
    end


endmodule

