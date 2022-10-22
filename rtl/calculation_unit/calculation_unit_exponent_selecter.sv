

module calculation_unit_exponent_selecter(
    input   calc1::exponent_select                   calculation_exponent_select,
    input   logic                            [7:0]   aligned_exponent_a,
    input   logic                            [7:0]   aligned_exponent_b,
    input   logic                            [9:0]   exponent_adder,
    input   logic                            [9:0]   exponent_subtractor,

    output  logic                            [9:0]   calculated_exponent
    );


    always_comb begin
        casex(calculation_exponent_select)
            calc1::A:     calculated_exponent = {{2{aligned_exponent_a[7]}}, aligned_exponent_a};
            calc1::B:     calculated_exponent = {{2{aligned_exponent_b[7]}}, aligned_exponent_b};
            calc1::ADD:   calculated_exponent = exponent_adder;
            calc1::SUB:   calculated_exponent = exponent_subtractor;
            calc1::B_SHR: calculated_exponent = {{3{aligned_exponent_b[7]}}, aligned_exponent_b[7:1]};  // this divides the exponent by 2 to calculate it's square root.
            default:      calculated_exponent = {{2{aligned_exponent_a[7]}}, aligned_exponent_a};
        endcase
    end


endmodule

