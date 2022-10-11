

module calculation_unit_fraction_selecter(
    input   calculation::calculation_select          calculation_select,
    input   logic                            [48:0]  fraction_adder,       // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic                            [48:0]  fraction_subtractor,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic                            [48:0]  fraction_multiplier,  // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    input   logic                            [25:0]  quotient_root,        // is [x.xxxx...]  format with 1 integer bits  25 fractional bits

    output  logic                            [48:0]  calculated_fraction   // is [xx.xxxx...] format with 2 integer bits, 47 fractional bits
    );


    always_comb begin
        casex(calculation_select)
            calculation::ADD:  calculated_fraction = fraction_adder;
            calculation::SUB:  calculated_fraction = fraction_subtractor;
            calculation::MUL:  calculated_fraction = fraction_multiplier;
            calculation::DIV,
            calculation::SQRT: calculated_fraction = {1'b0, quotient_root, 22'd0};
            default:           calculated_fraction = fraction_adder; 
        endcase
    end


endmodule

