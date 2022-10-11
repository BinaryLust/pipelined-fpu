

module calculation_unit(
    input   logic                                    clk,
    input   logic                                    reset,
    input   calculation::calculation_select          calculation_select,
    input   logic                                    divider_mode,
    input   logic                                    divider_start,
    input   logic                            [7:0]   sorted_exponent_a,
    input   logic                            [23:0]  sorted_fraction_a,    // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    input   logic                            [7:0]   sorted_exponent_b,
    input   logic                            [48:0]  aligned_fraction_b,   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic                                    busy,
    output  logic                                    done,
    output  logic                            [26:0]  remainder,
    output  logic                            [9:0]   calculated_exponent,
    output  logic                            [48:0]  calculated_fraction   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    logic  [9:0]   exponent_adder;
    logic  [9:0]   exponent_subtractor;
    logic  [48:0]  fraction_adder;       // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    logic  [48:0]  fraction_subtractor;  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    logic  [48:0]  fraction_multiplier;  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    logic  [25:0]  quotient_root;        // is [x.xxxx...]  format with 1 integer bits  25 fractional bits


    calculation_unit_exponent_adder
    calculation_unit_exponent_adder(
        .sorted_exponent_a,
        .sorted_exponent_b,
        .exponent_adder
    );
    

    calculation_unit_exponent_subtractor
    calculation_unit_exponent_subtractor(
        .sorted_exponent_a,
        .sorted_exponent_b,
        .exponent_subtractor
    );


    calculation_unit_exponent_selecter
    calculation_unit_exponent_selecter(
        .calculation_select,
        .sorted_exponent_a,
        .sorted_exponent_b,
        .exponent_adder,
        .exponent_subtractor,
        .calculated_exponent
    );


    calculation_unit_fraction_adder
    calculation_unit_fraction_adder(
        sorted_fraction_a,
        aligned_fraction_b,
        fraction_adder
    );


    calculation_unit_fraction_subtractor
    calculation_unit_fraction_subtractor(
        sorted_fraction_a,
        aligned_fraction_b,
        fraction_subtractor
    );


    calculation_unit_fraction_multiplier
    calculation_unit_fraction_multiplier(
        .sorted_fraction_a,
        .aligned_fraction_b,
        .fraction_multiplier
    );


    multi_norm_combined #(.INWIDTH(25), .OUTWIDTH(26))
    multi_norm_combined(
        .clk,
        .reset,
        .mode                   (divider_mode),
        .start                  (divider_start),
        .dividend_in            ({sorted_fraction_a, 1'b0}),
        .divisor_radicand_in    (aligned_fraction_b[47:23]),
        .busy,
        .done,
        .quotient_root,
        .remainder
    );


    calculation_unit_fraction_selecter
    calculation_unit_fraction_selecter(
        .calculation_select,
        .fraction_adder,
        .fraction_subtractor,
        .fraction_multiplier,
        .quotient_root,
        .calculated_fraction
    );


endmodule

