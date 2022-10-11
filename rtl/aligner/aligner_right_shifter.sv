

module aligner_right_shifter(
    input   logic  [4:0]   shift_count,
    input   logic  [23:0]  operand,

    output  logic  [47:0]  result
    );


    logic  [24:0]  right_shift_1;
    logic  [26:0]  right_shift_2;
    logic  [30:0]  right_shift_4;
    logic  [38:0]  right_shift_8;
    logic  [54:0]  right_shift_16;


    always_comb begin
        right_shift_1  = (shift_count[0]) ? {1'd0,  operand}       : {operand,       1'd0};
        right_shift_2  = (shift_count[1]) ? {2'd0,  right_shift_1} : {right_shift_1, 2'd0};
        right_shift_4  = (shift_count[2]) ? {4'd0,  right_shift_2} : {right_shift_2, 4'b0};
        right_shift_8  = (shift_count[3]) ? {8'd0,  right_shift_4} : {right_shift_4, 8'b0};
        right_shift_16 = (shift_count[4]) ? {16'd0, right_shift_8} : {right_shift_8, 16'b0};
        result         = right_shift_16[54:7]; // discard the lower bits
    end


endmodule

