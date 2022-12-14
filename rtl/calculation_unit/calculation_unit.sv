

module calculation_unit(
    input   logic                                    clk,
    input   logic                                    reset,
    input   calc1::exponent_select                   calculation_exponent_select,
    input   calc2::fraction_select                   calculation_fraction_select,
    input   logic                                    division_mode,
    input   logic                                    division_op,
    input   logic                            [7:0]   aligned_exponent_a,
    input   logic                            [23:0]  aligned_fraction_a,   // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    input   logic                            [7:0]   aligned_exponent_b,
    input   logic                            [48:0]  aligned_fraction_b,   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

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
        .aligned_exponent_a,
        .aligned_exponent_b,
        .exponent_adder
    );
    

    calculation_unit_exponent_subtractor
    calculation_unit_exponent_subtractor(
        .aligned_exponent_a,
        .aligned_exponent_b,
        .exponent_subtractor
    );


    calculation_unit_exponent_selecter
    calculation_unit_exponent_selecter(
        .calculation_exponent_select,
        .aligned_exponent_a,
        .aligned_exponent_b,
        .exponent_adder,
        .exponent_subtractor,
        .calculated_exponent
    );


    calculation_unit_fraction_adder
    calculation_unit_fraction_adder(
        aligned_fraction_a,
        aligned_fraction_b,
        fraction_adder
    );


    calculation_unit_fraction_subtractor
    calculation_unit_fraction_subtractor(
        aligned_fraction_a,
        aligned_fraction_b,
        fraction_subtractor
    );


    calculation_unit_fraction_multiplier
    calculation_unit_fraction_multiplier(
        .aligned_fraction_a,
        .aligned_fraction_b,
        .fraction_multiplier
    );


    multi_norm_combined #(.INWIDTH(25), .OUTWIDTH(26))
    multi_norm_combined(
        .clk,
        .reset,
        .mode                   (division_mode),
        .start                  (division_op & ~done),
        .dividend_in            ({aligned_fraction_a, 1'b0}),
        .divisor_radicand_in    (aligned_fraction_b[47:23]),
        .busy                   (),
        .done,
        .quotient_root,
        .remainder
    );


    calculation_unit_fraction_selecter
    calculation_unit_fraction_selecter(
        .calculation_fraction_select,
        .fraction_adder,
        .fraction_subtractor,
        .fraction_multiplier,
        .quotient_root,
        .calculated_fraction
    );


endmodule

