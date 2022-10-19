

module rounding_unit_normalizer(
    input   logic          normalize,
    input   logic  [9:0]   normalized_exponent,
    input   logic  [31:0]  rounded_fraction,     // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits

    output  logic  [9:0]   result_exponent,
    output  logic  [31:0]  result_fraction       // is [xx.xxxx...] format with 2 integer bits, 30 fractional bits
    );


    // normalize and add bias back in to exponent
    always_comb begin
        result_fraction =                        (normalize & rounded_fraction[31]) ? rounded_fraction >> 1 : rounded_fraction;
        result_exponent = normalized_exponent + ((normalize & rounded_fraction[31]) ? 10'd128               : 10'd127);           // add 1 + bias or just bias
    end


endmodule

