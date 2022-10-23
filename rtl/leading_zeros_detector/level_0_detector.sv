

module level_0_detector(
    input   logic  [3:0]  bits,
    output  logic  [1:0]  level_0_count,
    output  logic         level_0_zeros
    );


    always_comb begin
        casex(bits)
            4'b1???: {level_0_zeros, level_0_count} = {1'b0, 2'd0};
            4'b01??: {level_0_zeros, level_0_count} = {1'b0, 2'd1};
            4'b001?: {level_0_zeros, level_0_count} = {1'b0, 2'd2};
            4'b0001: {level_0_zeros, level_0_count} = {1'b0, 2'd3};
            4'b0000: {level_0_zeros, level_0_count} = {1'b1, 2'd0};
        endcase
    end


endmodule

