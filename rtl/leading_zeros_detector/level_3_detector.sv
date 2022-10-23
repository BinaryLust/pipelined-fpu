

module level_3_detector(
    input   logic  [1:0][3:0] level_2_count,
    input   logic  [1:0]      level_2_zeros,
    output  logic  [4:0]      level_3_count,
    output  logic             level_3_zeros
    );


    always_comb begin
        casex(level_2_zeros[1:0])
            2'b0?: {level_3_zeros, level_3_count} = {2'd0, level_2_count[1]};
            2'b10: {level_3_zeros, level_3_count} = {2'd1, level_2_count[0]};
            2'b11: {level_3_zeros, level_3_count} = {2'd2, 4'd0            };
        endcase
    end


endmodule

