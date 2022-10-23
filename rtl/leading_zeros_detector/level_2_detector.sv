

module level_2_detector(
    input   logic  [1:0][2:0] level_1_count,
    input   logic  [1:0]      level_1_zeros,
    output  logic  [3:0]      level_2_count,
    output  logic             level_2_zeros
    );


    always_comb begin
        casex(level_1_zeros[1:0])
            2'b0?: {level_2_zeros, level_2_count} = {2'd0, level_1_count[1]};
            2'b10: {level_2_zeros, level_2_count} = {2'd1, level_1_count[0]};
            2'b11: {level_2_zeros, level_2_count} = {2'd2, 3'd0            };
        endcase
    end


endmodule

