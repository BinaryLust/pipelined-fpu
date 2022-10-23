

// this is designed to be optimized for an Altera/Intel Max 10 FPGA with 4 input LUT's.
// the logic is 4 LUT's deep when synthesized, and will run at about 403 MHz Fmax (bounded to 250 Mhz because that's as fast as it can go)
// if registered at the inputs and outputs. it will use 56 LUT's for a 32-bit detector.
// the original leading zeros detector could only run at 323 Mhz Fmax and was 6 LUT's layers deep.


module leading_zeros_detector(
    input   logic  [31:0]  bits,
    output  logic  [4:0]   zeros,
    output  logic          all_zeros
    );


    // count are the lower bits, zeros is the upper most bit of the count.
    // it is split off just to make things easier to read.
    logic  [7:0][1:0]  level_0_count;
    logic  [7:0]       level_0_zeros;
    logic  [3:0][2:0]  level_1_count;
    logic  [3:0]       level_1_zeros;
    logic  [1:0][3:0]  level_2_count;
    logic  [1:0]       level_2_zeros;


    // level 0 modules
    level_0_detector
    level_0_detector_7(
        .bits             (bits[31:28]),
        .level_0_count    (level_0_count[7]),
        .level_0_zeros    (level_0_zeros[7])
    );

    level_0_detector
    level_0_detector_6(
        .bits             (bits[27:24]),
        .level_0_count    (level_0_count[6]),
        .level_0_zeros    (level_0_zeros[6])
    );

    level_0_detector
    level_0_detector_5(
        .bits             (bits[23:20]),
        .level_0_count    (level_0_count[5]),
        .level_0_zeros    (level_0_zeros[5])
    );

    level_0_detector
    level_0_detector_4(
        .bits             (bits[19:16]),
        .level_0_count    (level_0_count[4]),
        .level_0_zeros    (level_0_zeros[4])
    );

    level_0_detector
    level_0_detector_3(
        .bits             (bits[15:12]),
        .level_0_count    (level_0_count[3]),
        .level_0_zeros    (level_0_zeros[3])
    );

    level_0_detector
    level_0_detector_2(
        .bits             (bits[11:8]),
        .level_0_count    (level_0_count[2]),
        .level_0_zeros    (level_0_zeros[2])
    );

    level_0_detector
    level_0_detector_1(
        .bits             (bits[7:4]),
        .level_0_count    (level_0_count[1]),
        .level_0_zeros    (level_0_zeros[1])
    );

    level_0_detector
    level_0_detector_0(
        .bits             (bits[3:0]),
        .level_0_count    (level_0_count[0]),
        .level_0_zeros    (level_0_zeros[0])
    );


    // level 1 modules
    level_1_detector
    level_1_detector_3(
        .level_0_count    (level_0_count[7:6]),
        .level_0_zeros    (level_0_zeros[7:6]),
        .level_1_count    (level_1_count[3]),
        .level_1_zeros    (level_1_zeros[3])
    );

    level_1_detector
    level_1_detector_2(
        .level_0_count    (level_0_count[5:4]),
        .level_0_zeros    (level_0_zeros[5:4]),
        .level_1_count    (level_1_count[2]),
        .level_1_zeros    (level_1_zeros[2])
    );

    level_1_detector
    level_1_detector_1(
        .level_0_count    (level_0_count[3:2]),
        .level_0_zeros    (level_0_zeros[3:2]),
        .level_1_count    (level_1_count[1]),
        .level_1_zeros    (level_1_zeros[1])
    );

    level_1_detector
    level_1_detector_0(
        .level_0_count    (level_0_count[1:0]),
        .level_0_zeros    (level_0_zeros[1:0]),
        .level_1_count    (level_1_count[0]),
        .level_1_zeros    (level_1_zeros[0])
    );


    // level 2 modules
    level_2_detector
    level_2_detector_1(
        .level_1_count    (level_1_count[3:2]),
        .level_1_zeros    (level_1_zeros[3:2]),
        .level_2_count    (level_2_count[1]),
        .level_2_zeros    (level_2_zeros[1])
    );

    level_2_detector
    level_2_detector_0(
        .level_1_count    (level_1_count[1:0]),
        .level_1_zeros    (level_1_zeros[1:0]),
        .level_2_count    (level_2_count[0]),
        .level_2_zeros    (level_2_zeros[0])
    );


    // level 3 module
    level_3_detector
    level_3_detector(
        .level_2_count    (level_2_count[1:0]),
        .level_2_zeros    (level_2_zeros[1:0]),
        .level_3_count    (zeros),
        .level_3_zeros    (all_zeros)
    );


endmodule

