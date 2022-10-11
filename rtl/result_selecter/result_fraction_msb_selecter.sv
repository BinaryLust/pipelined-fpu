

module result_fraction_msb_selecter(
    input   fraction_msb::fraction_msb_select            fraction_msb_select,
    input   logic                                [23:0]  operand_fraction_a,
    input   logic                                [23:0]  operand_fraction_b,
    input   logic                                [24:0]  result_fraction,

    output  logic                                        result_22
    );


    always_comb begin
        case(fraction_msb_select)
            fraction_msb::ZERO:   result_22 = 1'b0;
            fraction_msb::ONE:    result_22 = 1'b1;
            fraction_msb::A:      result_22 = operand_fraction_a[22];
            fraction_msb::B:      result_22 = operand_fraction_b[22];
            fraction_msb::RESULT: result_22 = result_fraction[22];
            default:              result_22 = 1'b0;
        endcase
    end


endmodule

