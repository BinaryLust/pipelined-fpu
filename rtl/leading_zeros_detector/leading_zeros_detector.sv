

module leading_zeros_detector(
    input   logic  [31:0]  value,
    output  logic  [4:0]   zeros
    );


    logic  [7:0][1:0]  zero_group;
    logic  [7:0]       all_zeros;


    always_comb begin
        casex(all_zeros)
            8'b0???_????: zeros = 5'd0  + zero_group[7];
            8'b10??_????: zeros = 5'd4  + zero_group[6];
            8'b110?_????: zeros = 5'd8  + zero_group[5];
            8'b1110_????: zeros = 5'd12 + zero_group[4];
            8'b1111_0???: zeros = 5'd16 + zero_group[3];
            8'b1111_10??: zeros = 5'd20 + zero_group[2];
            8'b1111_110?: zeros = 5'd24 + zero_group[1];
            8'b1111_1110: zeros = 5'd28 + zero_group[0];
            8'b1111_1111: zeros = 5'd31;                 // this should actually 32 but we are limiting it to 31 since that is the largest value possible here
        endcase
    end


    sub_zeros_detector
    sub_zeros_detector0(
        .value       (value[3:0]),
        .zeros       (zero_group[0]),
        .all_zeros   (all_zeros[0])
    );


    sub_zeros_detector
    sub_zeros_detector1(
        .value       (value[7:4]),
        .zeros       (zero_group[1]),
        .all_zeros   (all_zeros[1])
    );


    sub_zeros_detector
    sub_zeros_detector2(
        .value       (value[11:8]),
        .zeros       (zero_group[2]),
        .all_zeros   (all_zeros[2])
    );


    sub_zeros_detector
    sub_zeros_detector3(
        .value       (value[15:12]),
        .zeros       (zero_group[3]),
        .all_zeros   (all_zeros[3])
    );


    sub_zeros_detector
    sub_zeros_detector4(
        .value       (value[19:16]),
        .zeros       (zero_group[4]),
        .all_zeros   (all_zeros[4])
    );


    sub_zeros_detector
    sub_zeros_detector5(
        .value       (value[23:20]),
        .zeros       (zero_group[5]),
        .all_zeros   (all_zeros[5])
    );


    sub_zeros_detector
    sub_zeros_detector6(
        .value       (value[27:24]),
        .zeros       (zero_group[6]),
        .all_zeros   (all_zeros[6])
    );


    sub_zeros_detector
    sub_zeros_detector7(
        .value       (value[31:28]),
        .zeros       (zero_group[7]),
        .all_zeros   (all_zeros[7])
    );


endmodule

