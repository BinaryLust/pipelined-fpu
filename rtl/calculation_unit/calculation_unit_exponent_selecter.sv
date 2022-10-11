

module calculation_unit_exponent_selecter(
    input   calculation::calculation_select          calculation_select,
    input   logic                            [7:0]   sorted_exponent_a,
    input   logic                            [7:0]   sorted_exponent_b,
    input   logic                            [9:0]   exponent_adder,
    input   logic                            [9:0]   exponent_subtractor,

    output  logic                            [9:0]   calculated_exponent
    );


    always_comb begin
        casex(calculation_select)
            calculation::ADD,
            calculation::SUB:  calculated_exponent = {{2{sorted_exponent_a[7]}}, sorted_exponent_a};
            calculation::MUL:  calculated_exponent = exponent_adder;
            calculation::DIV:  calculated_exponent = exponent_subtractor;
            calculation::SQRT: calculated_exponent = {{3{sorted_exponent_b[7]}}, sorted_exponent_b[7:1]};  // this divides the exponent by 2 to calculate it's square root.
            default:           calculated_exponent = {{2{sorted_exponent_a[7]}}, sorted_exponent_a};
        endcase
    end


endmodule

