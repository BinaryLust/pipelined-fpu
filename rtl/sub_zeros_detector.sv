

module sub_zeros_detector(
    input   logic  [3:0]  value,
    output  logic  [1:0]  zeros,  // this zero count is only valid if the all_zeros line isn't set.
    output  logic         all_zeros
    );


    always_comb begin
        casex(value)
            4'b1???: begin all_zeros = 1'b0; zeros = 2'd0; end
            4'b01??: begin all_zeros = 1'b0; zeros = 2'd1; end
            4'b001?: begin all_zeros = 1'b0; zeros = 2'd2; end
            4'b0001: begin all_zeros = 1'b0; zeros = 2'd3; end
            4'b0000: begin all_zeros = 1'b1; zeros = 2'd0; end
        endcase
    end


endmodule

