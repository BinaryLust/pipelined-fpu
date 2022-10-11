

module calculation_unit_exponent_adder(
    input   logic                            [7:0]   sorted_exponent_a,
    input   logic                            [7:0]   sorted_exponent_b,

    output  logic                            [9:0]   exponent_adder
    );


    assign exponent_adder = unsigned'({{2{sorted_exponent_a[7]}}, sorted_exponent_a}) + unsigned'({{2{sorted_exponent_b[7]}}, sorted_exponent_b});


endmodule

