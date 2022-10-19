

module result_fraction_lsbs_selecter(
    input   fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select,
    input   logic                                [23:0]  operand_fraction_a,
    input   logic                                [23:0]  operand_fraction_b,
    input   logic                                [31:0]  result_fraction,       // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits

    output  logic                                [21:0]  result_21_0
    );


    always_comb begin
        case(fraction_lsbs_select)
            fraction_lsbs::ZEROS:   result_21_0 = 22'd0;
            fraction_lsbs::A:       result_21_0 = operand_fraction_a[21:0];
            fraction_lsbs::B:       result_21_0 = operand_fraction_b[21:0];
            fraction_lsbs::RESULT:  result_21_0 = result_fraction[28:7];
            fraction_lsbs::IRESULT: result_21_0 = result_fraction[21:0];
            default:                result_21_0 = 22'd0;
        endcase
    end


endmodule

