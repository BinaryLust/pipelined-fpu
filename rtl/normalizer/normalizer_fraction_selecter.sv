

module normalizer_fraction_selecter(
    input   logic  [48:0]  calculated_fraction,    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic  [48:0]  left_shifter_result,    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic  [48:0]  normalized_fraction     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    always_comb begin
        casex(calculated_fraction[48:47])
            2'b1?:   normalized_fraction = calculated_fraction >> 1; // number overflowed right shift by 1, used for add, sub, and mul
            2'b01:   normalized_fraction = calculated_fraction;      // number already normalized
            default: normalized_fraction = left_shifter_result;      // number underflowed left shift, shifting by 1 used by div, shifting by more than 1 used by add and sub.
        endcase
    end


endmodule

