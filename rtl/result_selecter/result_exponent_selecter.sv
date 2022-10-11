

module result_exponent_selecter(
    input   exponent::exponent_select                   exponent_select,
    input   logic                                [7:0]  operand_exponent_a,
    input   logic                                [7:0]  operand_exponent_b,
    input   logic                                [9:0]  result_exponent,

    output  logic                                [7:0]  result_30_23
    );


    always_comb begin
        case(exponent_select)
            exponent::ZEROS:  result_30_23 = 8'd0;    
            exponent::ONES:   result_30_23 = 8'd255;
            exponent::A:      result_30_23 = operand_exponent_a;
            exponent::B:      result_30_23 = operand_exponent_b;
            exponent::RESULT: result_30_23 = result_exponent[7:0];
            default:          result_30_23 = 8'd0;
        endcase
    end


endmodule

