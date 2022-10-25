

module result_selecter(
    input   logic                                        check_result,
    input   sign::sign_select                            sign_select,
    input   exponent::exponent_select                    exponent_select,
    input   fraction_msb::fraction_msb_select            fraction_msb_select,
    input   fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select,
    input   logic                                        operand_sign_a,
    input   logic                                        operand_sign_b,
    input   logic                                [7:0]   operand_exponent_a,
    input   logic                                [7:0]   operand_exponent_b,
    input   logic                                [23:0]  operand_fraction_a,
    input   logic                                [23:0]  operand_fraction_b,
    input   logic                                        result_sign,
    input   logic                                [9:0]   result_exponent,
    input   logic                                [31:0]  result_fraction,       // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits

    output  logic                                [31:0]  result
    );


    sign::sign_select                    sign_select_out;
    exponent::exponent_select            exponent_select_out;
    fraction_msb::fraction_msb_select    fraction_msb_select_out;
    fraction_lsbs::fraction_lsbs_select  fraction_lsbs_select_out;


    result_control_logic
    result_control_logic(
        .check_result,
        .sign_select_in               (sign_select),
        .exponent_select_in           (exponent_select),
        .fraction_msb_select_in       (fraction_msb_select),
        .fraction_lsbs_select_in      (fraction_lsbs_select),
        .result_exponent,
        .result_fraction,
        .sign_select_out,
        .exponent_select_out,
        .fraction_msb_select_out,
        .fraction_lsbs_select_out
    );


    result_sign_selecter
    result_sign_selecter(
        .sign_select                  (sign_select_out),
        .operand_sign_a,
        .operand_sign_b,
        .result_sign,
        .result_fraction,
        .result_31                    (result[31])
    );


    result_exponent_selecter
    result_exponent_selecter(
        .exponent_select              (exponent_select_out),
        .operand_exponent_a,
        .operand_exponent_b,
        .result_exponent,
        .result_fraction,
        .result_30_23                 (result[30:23])
    );


    result_fraction_msb_selecter
    result_fraction_msb_selecter(
        .fraction_msb_select          (fraction_msb_select_out),
        .operand_fraction_a,
        .operand_fraction_b,
        .result_fraction,
        .result_22                    (result[22])
    );


    result_fraction_lsbs_selecter
    result_fraction_lsbs_selecter(
        .fraction_lsbs_select         (fraction_lsbs_select_out),
        .operand_fraction_a,
        .operand_fraction_b,
        .result_fraction,
        .result_21_0                  (result[21:0])
    );


endmodule

