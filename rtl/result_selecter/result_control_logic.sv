

module result_control_logic(
    input   sign::sign_select                            sign_select_in,
    input   exponent::exponent_select                    exponent_select_in,
    input   fraction_msb::fraction_msb_select            fraction_msb_select_in,
    input   fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select_in,
    input   logic                                [9:0]   result_exponent,
    input   logic                                [31:0]  result_fraction,

    output  sign::sign_select                            sign_select_out,
    output  exponent::exponent_select                    exponent_select_out,
    output  fraction_msb::fraction_msb_select            fraction_msb_select_out,
    output  fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select_out
    );


    logic  result_zero;
    logic  result_overflow;
    logic  result_underflow;


    always_comb begin
        // check the bounds of the result
        result_zero      = ~|result_fraction; // might only need to check the upper 24-25 bits? like before.
        result_overflow  = (signed'(result_exponent) >= signed'(10'd255));
        result_underflow = (signed'(result_exponent) <= signed'(10'd0));


        if({sign_select_in, exponent_select_in, fraction_msb_select_in, fraction_lsbs_select_in} == {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT}) begin // only check the conditions below if the result is set to normal since they have lower priority
            casex({result_zero, result_overflow, result_underflow})
                3'b1??:  {sign_select_out, exponent_select_out, fraction_msb_select_out, fraction_lsbs_select_out} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};  // result fraction was zero so set zero as result, this has the highest priority.
                3'b010:  {sign_select_out, exponent_select_out, fraction_msb_select_out, fraction_lsbs_select_out} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};  // result overflowed so set infinity as result
                3'b001:  {sign_select_out, exponent_select_out, fraction_msb_select_out, fraction_lsbs_select_out} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};  // result underflowed so set zero as result
                default: {sign_select_out, exponent_select_out, fraction_msb_select_out, fraction_lsbs_select_out} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT}; // use actual results
            endcase
        end else begin
            {sign_select_out, exponent_select_out, fraction_msb_select_out, fraction_lsbs_select_out} = {sign_select_in, exponent_select_in, fraction_msb_select_in, fraction_lsbs_select_in}; // pass original control signals through
        end
    end


endmodule

