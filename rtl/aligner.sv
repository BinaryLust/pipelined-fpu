

module aligner(
    input   logic          exchange_operands,
    input   logic  [4:0]   align_shift_count,
    input   logic          sign_a,
    input   logic  [7:0]   exponent_a,
    input   logic  [23:0]  fraction_a,
    input   logic          sign_b,
    input   logic  [7:0]   exponent_b,
    input   logic  [23:0]  fraction_b,

    output  logic          sorted_sign_a,
    output  logic  [7:0]   sorted_exponent_a,
    output  logic  [23:0]  sorted_fraction_a,  // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    output  logic          sorted_sign_b,
    output  logic  [7:0]   sorted_exponent_b,
    output  logic  [23:0]  sorted_fraction_b,  // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    output  logic  [48:0]  aligned_fraction_b  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    logic  [47:0]  right_shifter_result;   // is [x.xxxx...]  format with 1 integer bit,  47 fractional bits


    // sort operands, we will only do this for addition and subtraction operations, for all other operations we just pass the values through.
    operand_exchanger
    operand_exchanger(
        .exchange_operands,
        .sign_a,
        .exponent_a,
        .fraction_a,
        .sign_b,
        .exponent_b,
        .fraction_b,
        .sorted_sign_a,
        .sorted_exponent_a,
        .sorted_fraction_a,
        .sorted_sign_b,
        .sorted_exponent_b,
        .sorted_fraction_b
    );


    // we do the actual alignment with this right shifter
    right_shifter
    right_shifter(
        .shift_count    (align_shift_count),
        .operand        (sorted_fraction_b),
        .result         (right_shifter_result)
    );


    assign aligned_fraction_b = {1'b0, right_shifter_result};
    // aligned_exponent_a = 
    // aligned_exponent_b =


endmodule

