

module aligner(
    input   logic          exchange_operands,
    input   logic  [4:0]   align_shift_count,
    input   logic          operand_sign_a,
    input   logic  [7:0]   unbiased_exponent_a,
    input   logic  [23:0]  operand_fraction_a,
    input   logic          operand_sign_b,
    input   logic  [7:0]   unbiased_exponent_b,
    input   logic  [23:0]  operand_fraction_b,

    output  logic          aligned_sign_a,
    output  logic  [7:0]   aligned_exponent_a,
    output  logic  [23:0]  aligned_fraction_a,  // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    output  logic          aligned_sign_b,
    output  logic  [7:0]   aligned_exponent_b,
    output  logic  [48:0]  aligned_fraction_b   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    logic  [23:0]  sorted_fraction_b;     // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    logic  [47:0]  right_shifter_result;  // is [x.xxxx...]  format with 1 integer bit,  47 fractional bits


    // sort operands, we will only do this for addition and subtraction operations, for all other operations we just pass the values through.
    aligner_operand_exchanger
    aligner_operand_exchanger(
        .exchange_operands,
        .operand_sign_a,
        .unbiased_exponent_a,
        .operand_fraction_a,
        .operand_sign_b,
        .unbiased_exponent_b,
        .operand_fraction_b,
        .sorted_sign_a          (aligned_sign_a),
        .sorted_exponent_a      (aligned_exponent_a),
        .sorted_fraction_a      (aligned_fraction_a),
        .sorted_sign_b          (aligned_sign_b),
        .sorted_exponent_b      (aligned_exponent_b),
        .sorted_fraction_b
    );


    // we do the actual alignment with this right shifter
    aligner_right_shifter
    aligner_right_shifter(
        .shift_count    (align_shift_count),
        .operand        (sorted_fraction_b),
        .result         (right_shifter_result)
    );


    assign aligned_fraction_b = {1'b0, right_shifter_result};


endmodule

