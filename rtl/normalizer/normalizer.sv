

module normalizer(
    input   logic          normalize,
    input   logic  [9:0]   calculated_exponent,
    input   logic  [48:0]  calculated_fraction,    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic  [9:0]   normalized_exponent,
    output  logic  [48:0]  normalized_fraction     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    logic  [4:0]   normalize_shift_count;
    logic  [48:0]  left_shifter_result;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    logic  [9:0]   added_exponent;
    logic  [9:0]   subtracted_exponent;


    normalizer_exponent_adder
    normalizer_exponent_adder(
        .calculated_exponent,
        .added_exponent
    );


    normalizer_exponent_subtractor
    normalizer_exponent_subtractor(
        .calculated_exponent,
        .normalize_shift_count,
        .subtracted_exponent
    );


    leading_zeros_detector
    leading_zeros_detector(
        .bits           (calculated_fraction[47:16]),
        .zeros          (normalize_shift_count),
        .all_zeros      ()
    );


    normalizer_left_shifter
    normalizer_left_shifter(
        .shift_count    (normalize_shift_count),
        .operand        (calculated_fraction),
        .result         (left_shifter_result)
    );


    normalizer_exponent_selecter
    normalizer_exponent_selecter(
        .normalize,
        .calculated_exponent,
        .added_exponent,
        .subtracted_exponent,
        .calculated_fraction,
        .normalized_exponent
    );


    normalizer_fraction_selecter
    normalizer_fraction_selecter(
        .normalize,
        .calculated_fraction,
        .left_shifter_result,
        .normalized_fraction
    );


endmodule

