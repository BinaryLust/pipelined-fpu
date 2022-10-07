

package fpu;

    typedef  enum  logic  [2:0]
    {
        NORMAL    = 3'b00?,
        ZERO      = 3'b101,
        INFINITE  = 3'b011,
        NAN       = 3'b010,
        SUBNORMAL = 3'b100,
        DONTCARE  = 3'b???
    }   operand_types;

endpackage


module control_logic(
    input   logic  [2:0]   op,
    input   logic          sign_a,
    input   logic  [7:0]   exponent_a,
    input   logic  [23:0]  fraction_a,
    input   logic          sign_b,
    input   logic  [7:0]   exponent_b,
    input   logic  [23:0]  fraction_b,
    input   logic          sorted_sign_a,
    input   logic  [7:0]   sorted_exponent_a,
    input   logic          sorted_sign_b,
    input   logic  [7:0]   sorted_exponent_b,

    output  fpu::operand_types  operand_type_a,
    output  fpu::operand_types  operand_type_b,
    output  logic          exchange_operands,
    output  logic  [4:0]   align_shift_count,
    output  logic          post_sign
    );


    logic                 exponent_all_zeros_a;
    logic                 exponent_all_ones_a;
    logic                 fraction_all_zeros_a;
    logic                 exponent_all_zeros_b;
    logic                 exponent_all_ones_b;
    logic                 fraction_all_zeros_b;
    logic          [7:0]  exponent_difference;


    always_comb begin
        // do checks on exponent and fraction
        exponent_all_zeros_a = ~|exponent_a;
        exponent_all_ones_a  =  &exponent_a;
        fraction_all_zeros_a = ~|fraction_a[22:0];

        exponent_all_zeros_b = ~|exponent_b;
        exponent_all_ones_b  =  &exponent_b;
        fraction_all_zeros_b = ~|fraction_b[22:0];


        // form the bits for the type of each operand
        operand_type_a = fpu::operand_types'({exponent_all_zeros_a, exponent_all_ones_a, fraction_all_zeros_a});
        operand_type_b = fpu::operand_types'({exponent_all_zeros_b, exponent_all_ones_b, fraction_all_zeros_b});


        // compare operands to see if we need to exchange them.
        exchange_operands = ((op == 3'd0) | (op == 3'd1)) & ({exponent_a, fraction_a} < {exponent_b, fraction_b});


        // calculate the right shift count for the alignment step
        exponent_difference = sorted_exponent_a - sorted_exponent_b;
        case(op)
            3'd0,
            3'd1:    align_shift_count = (~|exponent_difference[7:5]) ? exponent_difference[4:0] : 5'd31; // for addition and subtraction, this checks to make sure the upper 3 bits of the difference are zero, if that is so then the difference is 31 or less and it is used.
            3'd4:    align_shift_count = (sorted_exponent_b[0]) ? 5'd1 : 5'd0; // for square root. the exponent must be an even number because it has to be divided by 2 (this is to find the square root of the exponent), so we check if it's even and right shift by 1 if it's not.
            default: align_shift_count = 5'd0;
        endcase


        // sign calculation
        case(op)
            3'd0:    post_sign = sorted_sign_a;                                        // for add
            3'd1:    post_sign = (exchange_operands) ? ~sorted_sign_a : sorted_sign_a; // for sub
            default: post_sign = sign_a ^ sign_b;                                      // for mul, div
        endcase
    end


endmodule

