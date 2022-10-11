

module calculation_unit_exponent_subtractor(
    input   logic                            [7:0]   sorted_exponent_a,
    input   logic                            [7:0]   sorted_exponent_b,

    output  logic                            [9:0]   exponent_subtractor
    );


    assign exponent_subtractor = unsigned'({{2{sorted_exponent_a[7]}}, sorted_exponent_a}) - unsigned'({{2{sorted_exponent_b[7]}}, sorted_exponent_b});


endmodule

