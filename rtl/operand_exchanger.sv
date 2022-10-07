

module operand_exchanger(
    input   logic          exchange_operands,
    input   logic          sign_a,
    input   logic  [7:0]   exponent_a,
    input   logic  [23:0]  fraction_a,
    input   logic          sign_b,
    input   logic  [7:0]   exponent_b,
    input   logic  [23:0]  fraction_b,

    output  logic          sorted_sign_a,
    output  logic  [7:0]   sorted_exponent_a,
    output  logic  [23:0]  sorted_fraction_a,
    output  logic          sorted_sign_b,
    output  logic  [7:0]   sorted_exponent_b,
    output  logic  [23:0]  sorted_fraction_b
    );


    always_comb begin
        if(exchange_operands) begin
            {sorted_sign_a, sorted_exponent_a, sorted_fraction_a} = {sign_b, exponent_b, fraction_b};
            {sorted_sign_b, sorted_exponent_b, sorted_fraction_b} = {sign_a, exponent_a, fraction_a};           
        end else begin
            {sorted_sign_a, sorted_exponent_a, sorted_fraction_a} = {sign_a, exponent_a, fraction_a};
            {sorted_sign_b, sorted_exponent_b, sorted_fraction_b} = {sign_b, exponent_b, fraction_b};
        end
    end


endmodule

