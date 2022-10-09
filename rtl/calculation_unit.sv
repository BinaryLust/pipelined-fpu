

module calculation_unit(
    input   logic                                    clk,
    input   logic                                    reset,
    input   calculation::calculation_select          calculation_select,
    input   logic                                    divider_mode,
    input   logic                                    divider_start,
    input   logic                            [7:0]   sorted_exponent_a,
    input   logic                            [23:0]  sorted_fraction_a,    // is [x.xxxx...]  format with 1 integer bits, 23 fractional bits
    input   logic                            [7:0]   sorted_exponent_b,
    input   logic                            [48:0]  aligned_fraction_b,   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits

    output  logic                                    busy,
    output  logic                                    done,
    output  logic                            [26:0]  remainder,
    output  logic                            [9:0]   calculated_exponent,
    output  logic                            [48:0]  calculated_fraction   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    logic  [25:0]  quotient_root;  // is [x.xxxx...]  format with 1 integer bits  25 fractional bits


    always_comb begin
        // exponent calculation
        casex(calculation_select)
            calculation::ADD,
            calculation::SUB:  calculated_exponent = sorted_exponent_a;
            calculation::MUL:  calculated_exponent = (unsigned'(sorted_exponent_a) + unsigned'(sorted_exponent_b)) - 10'd127;
            calculation::DIV:  calculated_exponent = (unsigned'(sorted_exponent_a) - unsigned'(sorted_exponent_b)) + 10'd127;
            calculation::SQRT: calculated_exponent = (sorted_exponent_b[7:1] + 10'd63) + sorted_exponent_b[0];  // this divides the exponent by 2, adds half the bias back in and if it was odd before increments the value by 1.
            default:           calculated_exponent = sorted_exponent_a;
        endcase


        // fraction calculation
        casex(calculation_select)
            calculation::ADD:  calculated_fraction = unsigned'({1'd0, sorted_fraction_a, 24'd0}) + unsigned'(aligned_fraction_b);
            calculation::SUB:  calculated_fraction = unsigned'({1'd0, sorted_fraction_a, 24'd0}) - unsigned'(aligned_fraction_b);
            calculation::MUL:  calculated_fraction = (unsigned'(sorted_fraction_a) * unsigned'(aligned_fraction_b[47:24])) << 1;
            calculation::DIV,
            calculation::SQRT: calculated_fraction = {1'b0, quotient_root, 22'd0};
            default:           calculated_fraction = unsigned'({1'd0, sorted_fraction_a, 24'd0}) + unsigned'(aligned_fraction_b); 
        endcase
    end


    multi_norm_combined #(.INWIDTH(25), .OUTWIDTH(26))
    multi_norm_combined(
        .clk,
        .reset,
        .mode                   (divider_mode),
        .start                  (divider_start),
        .dividend_in            ({sorted_fraction_a, 1'b0}),
        .divisor_radicand_in    (aligned_fraction_b[47:23]),
        .busy,
        .done,
        .quotient_root,
        .remainder
    );


endmodule

