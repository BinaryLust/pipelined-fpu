

module normalizer_left_shifter(
    input   logic  [4:0]   shift_count,
    input   logic  [48:0]  operand,

    output  logic  [48:0]  result
    );


    logic  [48:0]  left_shift_1;
    logic  [48:0]  left_shift_2;
    logic  [48:0]  left_shift_4;
    logic  [48:0]  left_shift_8;
    logic  [48:0]  left_shift_16;


    always_comb begin
        left_shift_1  = (shift_count[0]) ? {operand[47:0],      1'b0}  : operand;
        left_shift_2  = (shift_count[1]) ? {left_shift_1[46:0], 2'd0}  : left_shift_1;
        left_shift_4  = (shift_count[2]) ? {left_shift_2[44:0], 4'd0}  : left_shift_2;
        left_shift_8  = (shift_count[3]) ? {left_shift_4[40:0], 8'd0}  : left_shift_4;
        left_shift_16 = (shift_count[4]) ? {left_shift_8[32:0], 16'd0} : left_shift_8;
        result        = left_shift_16;
    end


endmodule

