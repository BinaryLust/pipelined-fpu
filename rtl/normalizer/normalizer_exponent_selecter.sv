

module normalizer_exponent_selecter(
    input   logic          normalize,
    input   logic  [9:0]   calculated_exponent,
    input   logic  [9:0]   added_exponent,
    input   logic  [9:0]   subtracted_exponent,
    input   logic  [48:0]  calculated_fraction,    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic  [9:0]   normalized_exponent
    );


    always_comb begin
        casex({normalize, calculated_fraction[48:47]})
            3'b0??: normalized_exponent = calculated_exponent;  // skip normalization and just pass the value through
            3'b11?: normalized_exponent = added_exponent;       // number overflowed right shift by 1, used for add, sub, and mul
            3'b101: normalized_exponent = calculated_exponent;  // number already normalized
            3'b100: normalized_exponent = subtracted_exponent;  // number underflowed left shift, shifting by 1 used by div, shifting by more than 1 used by add and sub.
        endcase
    end


endmodule

