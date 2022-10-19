

module result_sign_selecter(
    input   sign::sign_select                            sign_select,
    input   logic                                        operand_sign_a,
    input   logic                                        operand_sign_b,
    input   logic                                        result_sign,
    input   logic                                [31:0]  result_fraction,  // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits

    output  logic                                        result_31
    );


    always_comb begin
        case(sign_select)
            sign::ZERO:    result_31 = 1'b0;
            sign::ONE:     result_31 = 1'b1;
            sign::A:       result_31 = operand_sign_a;
            sign::B:       result_31 = operand_sign_b;
            sign::NB:      result_31 = ~operand_sign_b;
            sign::A_B:     result_31 = operand_sign_a & operand_sign_b;
            sign::A_NB:    result_31 = operand_sign_a & ~operand_sign_b;
            sign::RESULT:  result_31 = result_sign;
            sign::IRESULT: result_31 = result_fraction[31];
            default:       result_31 = 1'b0;
        endcase
    end


endmodule

