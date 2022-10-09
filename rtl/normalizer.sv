

module normalizer(
    input   logic  [9:0]   calculated_exponent,
    input   logic  [48:0]  calculated_fraction,    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic  [9:0]   normalized_exponent,
    output  logic  [48:0]  normalized_fraction     // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    logic  [4:0]   normalize_shift_count;
    logic  [48:0]  left_shifter_result;    // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits


    always_comb begin
        casex(calculated_fraction[48:47])
            2'b1?:   begin // number overflowed right shift by 1, used for add, sub, and mul
                         normalized_fraction = calculated_fraction >> 1;
                         normalized_exponent = calculated_exponent + 10'd1;
                     end
            2'b01:   begin // number already normalized
                         normalized_fraction = calculated_fraction;
                         normalized_exponent = calculated_exponent;
                     end
            default: begin // number underflowed left shift, shifting by 1 used by div, shifting by more than 1 used by add and sub.
                         normalized_fraction = left_shifter_result;
                         normalized_exponent = calculated_exponent - normalize_shift_count;
                     end
        endcase
    end


    leading_zeros_detector
    leading_zeros_detector(
        .value          (calculated_fraction[47:24]), // shouldn't this be 26-bits at the very least?
        .zeros          (normalize_shift_count)
    );


    left_shifter
    left_shifter(
        .shift_count    (normalize_shift_count),
        .operand        (calculated_fraction),
        .result         (left_shifter_result)
    );


endmodule

