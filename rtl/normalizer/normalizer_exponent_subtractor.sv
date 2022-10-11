

module normalizer_exponent_subtractor(
    input   logic  [9:0]   calculated_exponent,
    input   logic  [4:0]   normalize_shift_count,

    output  logic  [9:0]   subtracted_exponent
    );


    assign subtracted_exponent = calculated_exponent - {5'd0, normalize_shift_count};


endmodule

