

module leading_zeros_detector(
    input   logic  [23:0]  value,
    output  logic  [4:0]   zeros
    );


    logic  [5:0][1:0]  zero_group;
    logic  [5:0]       all_zeros;


    always_comb begin
        casex(all_zeros)
            6'b10??_??: zeros = 5'd4  + zero_group[4];
            6'b110?_??: zeros = 5'd8  + zero_group[3];
            6'b1110_??: zeros = 5'd12 + zero_group[2];
            6'b1111_0?: zeros = 5'd16 + zero_group[1];
            6'b1111_10: zeros = 5'd20 + zero_group[0];
            6'b1111_11: zeros = 5'd24;
            default:    zeros = 5'd0  + zero_group[5];
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


endmodule

