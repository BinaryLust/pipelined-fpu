

module level_1_detector(
    input   logic  [1:0][1:0] level_0_count,
    input   logic  [1:0]      level_0_zeros,
    output  logic  [2:0]      level_1_count,
    output  logic             level_1_zeros
    );


    always_comb begin
        casex(level_0_zeros[1:0])
            2'b0?: {level_1_zeros, level_1_count} = {2'd0, level_0_count[1]};
            2'b10: {level_1_zeros, level_1_count} = {2'd1, level_0_count[0]};
            2'b11: {level_1_zeros, level_1_count} = {2'd2, 2'd0            };
        endcase
    end


endmodule

