

module normalizer_exponent_adder(
    input   logic  [9:0]   calculated_exponent,

    output  logic  [9:0]   added_exponent
    );


    assign added_exponent = calculated_exponent + 10'd1;


endmodule

