

module result_selecter(
    input   sign::sign_select                            sign_select,
    input   exponent::exponent_select                    exponent_select,
    input   fraction_msb::fraction_msb_select            fraction_msb_select,
    input   fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select,
    input   logic                                        sign_a,
    input   logic                                        sign_b,
    input   logic                                [7:0]   exponent_a,
    input   logic                                [7:0]   exponent_b,
    input   logic                                [23:0]  fraction_a,
    input   logic                                [23:0]  fraction_b,
    input   logic                                        result_sign,
    input   logic                                [9:0]   result_exponent,
    input   logic                                [24:0]  result_fraction,

    output  logic                                [31:0]  result
    );


    sign::sign_select                    sign_select_out;
    exponent::exponent_select            exponent_select_out;
    fraction_msb::fraction_msb_select    fraction_msb_select_out;
    fraction_lsbs::fraction_lsbs_select  fraction_lsbs_select_out;


    result_control_logic
    result_control_logic(
        .sign_select_in              (sign_select),
        .exponent_select_in          (exponent_select),
        .fraction_msb_select_in      (fraction_msb_select),
        .fraction_lsbs_select_in     (fraction_lsbs_select),
        .result_exponent,
        .result_fraction,
        .sign_select_out,
        .exponent_select_out,
        .fraction_msb_select_out,
        .fraction_lsbs_select_out
    );


    always_comb begin
        case(sign_select_out)
            sign::ZERO:            result[31]    = 1'b0;
            sign::ONE:             result[31]    = 1'b1;
            sign::A:               result[31]    = sign_a;
            sign::B:               result[31]    = sign_b;
            sign::NB:              result[31]    = ~sign_b;
            sign::A_B:             result[31]    = sign_a & sign_b;
            sign::A_NB:            result[31]    = sign_a & ~sign_b;
            sign::RESULT:          result[31]    = result_sign;
            default:               result[31]    = 1'b0;
        endcase


        case(exponent_select_out)
            exponent::ZEROS:       result[30:23] = 8'd0;    
            exponent::ONES:        result[30:23] = 8'd255;
            exponent::A:           result[30:23] = exponent_a;
            exponent::B:           result[30:23] = exponent_b;
            exponent::RESULT:      result[30:23] = result_exponent[7:0];
            default:               result[30:23] = 8'd0;
        endcase

    
        case(fraction_msb_select_out)
            fraction_msb::ZERO:    result[22]    = 1'b0;
            fraction_msb::ONE:     result[22]    = 1'b1;
            fraction_msb::A:       result[22]    = fraction_a[22];
            fraction_msb::B:       result[22]    = fraction_b[22];
            fraction_msb::RESULT:  result[22]    = result_fraction[22];
            default:               result[22]    = 1'b0;
        endcase


        case(fraction_lsbs_select_out)
            fraction_lsbs::ZEROS:  result[21:0]  = 22'd0;
            fraction_lsbs::A:      result[21:0]  = fraction_a[21:0];
            fraction_lsbs::B:      result[21:0]  = fraction_b[21:0];
            fraction_lsbs::RESULT: result[21:0]  = result_fraction[21:0];
            default:               result[21:0]  = 22'd0;
        endcase
    end


endmodule

