

module rounding_unit_fraction_incrementer(
    input   logic          rounding_mode,
    input   logic  [48:0]  normalized_fraction,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic  [31:0]  incremented_fraction  // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits
    );


    assign incremented_fraction = normalized_fraction[48:17] + ((rounding_mode) ?  32'd1 : {24'h0, 8'h80}); // this is bugged for some reason.


endmodule

