

module rounding_unit(
    input   logic          normalize,
    input   logic          rounding_mode,
    input   logic  [1:0]   sticky_bit_select,
    input   logic  [9:0]   normalized_exponent,
    input   logic  [48:0]  normalized_fraction,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic  [26:0]  remainder,

    output  logic  [9:0]   result_exponent,
    output  logic  [31:0]  result_fraction       // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits
    );


    logic          sticky_bit;
    logic  [31:0]  incremented_fraction;  // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits
    logic  [31:0]  rounded_fraction;      // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits


    rounding_unit_sticky_bit_selecter
    rounding_unit_sticky_bit_selecter(
        .sticky_bit_select,
        .normalized_fraction,
        .remainder,
        .sticky_bit
    );


    rounding_unit_fraction_incrementer
    rounding_unit_fraction_incrementer(
        .rounding_mode,
        .normalized_fraction,
        .incremented_fraction
    );


    rounding_unit_fraction_selecter
    rounding_unit_fraction_selecter(
        .rounding_mode,
        .sticky_bit,
        .normalized_fraction,
        .incremented_fraction,
        .rounded_fraction
    );


    rounding_unit_normalizer
    rounding_unit_normalizer(
        .normalize,
        .normalized_exponent,
        .rounded_fraction,
        .result_exponent,
        .result_fraction
    );


endmodule

