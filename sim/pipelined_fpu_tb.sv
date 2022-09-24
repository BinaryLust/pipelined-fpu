`timescale 1ns / 100ps

`define pZero   32'b0_00000000_00000000000000000000000 // positive zero
`define nZero   32'b1_00000000_00000000000000000000000 // negative zero
`define pInf    32'b0_11111111_00000000000000000000000 // positive infinity
`define nInf    32'b1_11111111_00000000000000000000000 // negative infinity
`define sNaN    32'b0_11111111_01000000000000000000000 // signaling not a number
`define qNaN    32'b0_11111111_10000000000000000000000 // quiet not a number
`define pDenorm 32'b0_00000000_00000000000000000000001 // positive smallest denormalized number
`define nDenorm 32'b1_00000000_00000000000000000000001 // negative smallest denormalized number


module pipelined_fpu_tb();


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* wire declaration                                                                                                                                      */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    // input wires
    logic        clk;
    logic        reset;
    logic        start;
    logic [31:0] a;


    // output wires
    logic        done;
    logic        busy;
    logic [31:0] result;


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* test module instantiation                                                                                                                             */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    pipelined_fpu
    dut(
        .clk,
        .reset,
        .start,
        .a,
        .done,
        .busy,
        .result
    );


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* testing variables                                                                                                                                     */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    integer            seed               = 17487;
    integer            errors             = 0;
    shortreal          float_a;
    shortreal          float_result;
    shortreal          expected_result;
    logic      [31:0]  bit_sexpected_result;


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* test stimulus                                                                                                                                         */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    // set initial values
    initial begin
        reset = 1'b0;
        start = 1'b0;
        a     = 32'd0;
    end


    // create clock sources
    always begin
        #5;
        clk = 1'b0;
        #5;
        clk = 1'b1;
    end


    // apply test stimulus
    // synopsys translate_off
    initial begin
        // set the random seed
        $urandom(seed);

        // reset the system
        hardware_reset();

        // run the constrained random test
        repeat(30000) begin
           @(posedge clk)
           start                = 1'b1;
           a                    = rand_float();

           @(posedge clk);
           start                = 1'b0;

           @(posedge done);
           @(negedge clk)
           float_a              = $bitstoshortreal(a);
           float_result         = $bitstoshortreal(result);
           expected_result      = (~|a[30:23] & |a[22:0]) ? $bitstoshortreal({a[31], 8'd0, 23'd0}) : $sqrt(float_a); // if input is denormal we expect 0 as the result, otherwise we expect the square root of the input.
           bit_sexpected_result = $shortrealtobits(expected_result);

           if(result != bit_sexpected_result) begin
               $warning("Result Miss Match on: sqrt(%.9g) got: %.9g expected: %.9g",
                   float_a,
                   float_result,
                   $bitstoshortreal(bit_sexpected_result)
               );
               $display("binary  got      - sign: %b exponent: %b fraction: %b\nbinary  expected - sign: %b exponent: %b fraction: %b",
                                       result[31],               result[30:23],               result[22:0],
                         bit_sexpected_result[31], bit_sexpected_result[30:23], bit_sexpected_result[22:0],
               );
               $display("decimal got      - sign: %b exponent: %d fraction: %d\ndecimal expected - sign: %b exponent: %d fraction: %d\n",
                                       result[31],               result[30:23],               result[22:0],
                         bit_sexpected_result[31], bit_sexpected_result[30:23], bit_sexpected_result[22:0],
               );
               errors++;
           end
        end

        // run a completely random test
        repeat(30000) begin
           @(posedge clk)
           start                = 1'b1;
           a                    = $urandom();

           @(posedge clk);
           start                = 1'b0;

           @(posedge done);
           @(negedge clk)
           float_a              = $bitstoshortreal(a);
           float_result         = $bitstoshortreal(result);
           expected_result      = (~|a[30:23] & |a[22:0]) ? $bitstoshortreal({a[31], 8'd0, 23'd0}) : $sqrt(float_a); // if input is denormal we expect 0 as the result, otherwise we expect the square root of the input.
           bit_sexpected_result = $shortrealtobits(expected_result);

           if(result != bit_sexpected_result) begin
               $warning("Result Miss Match on: sqrt(%.9g) got: %.9g expected: %.9g",
                   float_a,
                   float_result,
                   $bitstoshortreal(bit_sexpected_result)
               );
               $display("binary  got      - sign: %b exponent: %b fraction: %b\nbinary  expected - sign: %b exponent: %b fraction: %b",
                                       result[31],               result[30:23],               result[22:0],
                         bit_sexpected_result[31], bit_sexpected_result[30:23], bit_sexpected_result[22:0],
               );
               $display("decimal got      - sign: %b exponent: %d fraction: %d\ndecimal expected - sign: %b exponent: %d fraction: %d\n",
                                       result[31],               result[30:23],               result[22:0],
                         bit_sexpected_result[31], bit_sexpected_result[30:23], bit_sexpected_result[22:0],
               );
               errors++;
           end
        end

        $display("Total Errors: %d", errors);

        $stop;
    end
    // synopsys translate_on


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* tasks                                                                                                                                                 */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    task hardware_reset();
        reset = 1'b0;
        wait(clk !== 1'bx);
        @(posedge clk);
        reset = 1'b1;
        repeat(10) @(posedge clk);
        reset = 1'b0;
    endtask


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* functions                                                                                                                                             */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    function logic [31:0] rand_float();
        logic  [4:0]   r;
        logic          sign;
        logic  [7:0]   exponent;
        logic  [22:0]  fraction;
        logic          signal;

        r = $random();

        case(r)
            5'd0:    rand_float = `pZero;   // return postive zero
            5'd1:    rand_float = `nZero;   // return negative zero
            5'd2:    rand_float = `pInf;    // return positive infinity
            5'd3:    rand_float = `nInf;    // return negative infinity
            5'd4, 
            5'd5:    begin // return not a number (positive and negative)(signaling and quiet)
                         sign     = $urandom;
                         fraction = $urandom;
                         signal   = $urandom;
                         if(fraction == 22'b0) fraction = 22'b1; // make sure it isn't set to zero
                         rand_float = {sign, 8'b11111111, signal, fraction[21:0]};
                     end
            5'd6,
            5'd7:    begin // return a random subnormal number
                            sign       = $urandom;
                            fraction   = $urandom;
                            rand_float = {sign, 8'd0, fraction};
                     end
            5'd8:    begin // return smallest subnormal number
                            sign       = $urandom;
                            rand_float = {sign, 8'd0, 23'b000_0000_0000_0000_0000_0001};
                     end
            5'd9:    begin // return largest subnormal number
                            sign       = $urandom;
                            fraction   = $urandom;
                            rand_float = {sign, 8'd0, 23'b111_1111_1111_1111_1111_1111};
                     end
            5'd10:   begin // return smallest normalized number
                         sign       = $urandom;
                         rand_float = {sign, 8'd1, 23'b000_0000_0000_0000_0000_0001};
                     end
            5'd11:   begin // return largest normalized number
                         sign       = $urandom;
                         exponent   = $urandom_range(8'd1, 8'd244);
                         fraction   = $urandom;
                         rand_float = {sign, 8'd254, 23'b111_1111_1111_1111_1111_1111};
                     end
            default: begin // return a random normalized number
                         sign       = $urandom;
                         exponent   = $urandom_range(8'd1, 8'd244);
                         fraction   = $urandom;
                         rand_float = {sign, exponent, fraction};
                     end
        endcase
    endfunction


endmodule

