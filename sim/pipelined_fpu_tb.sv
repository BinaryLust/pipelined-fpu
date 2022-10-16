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
    logic [2:0]  op;
    logic        start;
    logic [31:0] operand_a;
    logic [31:0] operand_b;


    // output wires
    logic        stall;
    logic        valid;
    logic [31:0] result;


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* test module instantiation                                                                                                                             */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    pipelined_fpu_test_synthesis
    dut(
        .clk,
        .reset,
        .op,
        .start,
        .operand_a,
        .operand_b,
        .stall,
        .valid,
        .result
    );


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* testing variables                                                                                                                                     */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    integer            seed            = 987632;
    integer            errors          = 0;
    integer            cycles_per_test = 500000; // 50k is equal to the old 10k test size, 1.5M is equal to the old 300k test size
    logic      [2:0]   operation;
    logic      [31:0]  binary_a;
    logic      [31:0]  binary_b;
    shortreal          float_a;
    shortreal          float_b;
    shortreal          float_result;
    logic      [31:0]  expected_result;
    logic      [2:0]   op_queue[$];
    logic      [31:0]  a_queue[$];
    logic      [31:0]  b_queue[$];


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* test stimulus                                                                                                                                         */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    // set initial values
    initial begin
        reset     = 1'b0;
        op        = 3'd3;
        start     = 1'b0;
        operand_a = 32'd0;
        operand_b = 32'd0;
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


        // in order to more thoroughly test these functions we need to hand pick values whose outputs will be at the corner cases
        // like for subtraction we need to pick a value and subtract a value that is 1 fractional bit smaller and bigger from it
        // in order to make sure we are able to shift the whole 26 bits max range.


        // run the constrained random test
        repeat(cycles_per_test) begin
            @(posedge clk)
            #10
            wait(~stall)
            start           = 1'b1;
            op              = $urandom_range(3'd0, 3'd4);
            operand_a       = rand_float();
            operand_b       = rand_float();
            op_queue.push_front(op);
            a_queue.push_front(operand_a);
            b_queue.push_front(operand_b);
        end


        // run a completely random test
        repeat(cycles_per_test) begin
            @(posedge clk)
            #10
            wait(~stall)
            start           = 1'b1;
            op              = $urandom_range(3'd0, 3'd4);
            operand_a       = $urandom();
            operand_b       = $urandom();
            op_queue.push_front(op);
            a_queue.push_front(operand_a);
            b_queue.push_front(operand_b);
        end


        $display("Total Errors: %d", errors);

        $stop;
    end


    always begin
        @(posedge clk)
        #10
        wait(valid)
        operation       = op_queue.pop_back();
        binary_a        = a_queue.pop_back();
        binary_b        = b_queue.pop_back();
        float_a         = $bitstoshortreal(binary_a);
        float_b         = $bitstoshortreal(binary_b);
        float_result    = $bitstoshortreal(result);
        expected_result = expected(operation, binary_a, binary_b, float_a, float_b);

        if(result != expected_result) begin
            case(operation)
                3'd0: $warning("Result Miss Match on: %.9g + %.9g got: %.9g expected: %.9g", float_a, float_b, float_result, $bitstoshortreal(expected_result));
                3'd1: $warning("Result Miss Match on: %.9g - %.9g got: %.9g expected: %.9g", float_a, float_b, float_result, $bitstoshortreal(expected_result));
                3'd2: $warning("Result Miss Match on: %.9g * %.9g got: %.9g expected: %.9g", float_a, float_b, float_result, $bitstoshortreal(expected_result));
                3'd3: $warning("Result Miss Match on: %.9g / %.9g got: %.9g expected: %.9g", float_a, float_b, float_result, $bitstoshortreal(expected_result));
                3'd4: $warning("Result Miss Match on: sqrt(%.9g) got: %.9g expected: %.9g", float_b, float_result, $bitstoshortreal(expected_result));
            endcase

            $display("binary  got      - sign: %b exponent: %b fraction: %b\nbinary  expected - sign: %b exponent: %b fraction: %b",
                         result[31],          result[30:23],          result[22:0],
                expected_result[31], expected_result[30:23], expected_result[22:0],
            );
            $display("decimal got      - sign: %b exponent: %d fraction: %d\ndecimal expected - sign: %b exponent: %d fraction: %d\n",
                         result[31],          result[30:23],          result[22:0],
                expected_result[31], expected_result[30:23], expected_result[22:0],
            );
            errors++;
        end
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

        casex(r)
            5'd0:       rand_float = `pZero;   // return postive zero
            5'd1:       rand_float = `nZero;   // return negative zero
            5'd2:       rand_float = `pInf;    // return positive infinity
            5'd3:       rand_float = `nInf;    // return negative infinity
            5'd4, 
            5'd5:       begin // return not a number (positive and negative)(signaling and quiet)
                            sign       = $urandom;
                            fraction   = $urandom;
                            signal     = $urandom;
                            if(fraction == 22'b0) fraction = 22'b1; // make sure it isn't set to zero
                            rand_float = {sign, 8'b11111111, signal, fraction[21:0]};
                        end
            5'd6,
            5'd7:       begin // return a random subnormal number
                            sign       = $urandom;
                            fraction   = $urandom;
                            rand_float = {sign, 8'd0, fraction};
                        end
            5'd8:       begin // return smallest subnormal number
                            sign       = $urandom;
                            rand_float = {sign, 8'd0, 23'b000_0000_0000_0000_0000_0001};
                        end
            5'd9:       begin // return largest subnormal number
                            sign       = $urandom;
                            fraction   = $urandom;
                            rand_float = {sign, 8'd0, 23'b111_1111_1111_1111_1111_1111};
                        end
            5'd10:      begin // return smallest normalized number
                            sign       = $urandom;
                            rand_float = {sign, 8'd1, 23'b000_0000_0000_0000_0000_0001};
                        end
            5'd11:      begin // return largest normalized number
                            sign       = $urandom;
                            exponent   = $urandom_range(8'd1, 8'd244);
                            fraction   = $urandom;
                            rand_float = {sign, 8'd254, 23'b111_1111_1111_1111_1111_1111};
                        end
            default:    begin // return a random normalized number
                            sign       = $urandom;
                            exponent   = $urandom_range(8'd1, 8'd244);
                            fraction   = $urandom;
                            rand_float = {sign, exponent, fraction};
                        end
        endcase
    endfunction


    function logic [31:0] expected(logic [2:0] operation, logic [31:0] binary_a, logic[31:0] binary_b, shortreal float_a, shortreal float_b);
        automatic logic  [31:0]  temp;
        automatic logic          a_denorm = ~|binary_a[30:23] & |binary_a[22:0];
        automatic logic          b_denorm = ~|binary_b[30:23] & |binary_b[22:0];


        float_a = (a_denorm) ? $bitstoshortreal({binary_a[31], 8'd0, 23'd0}) : float_a;
        float_b = (b_denorm) ? $bitstoshortreal({binary_b[31], 8'd0, 23'd0}) : float_b;


        casex(operation)
            3'd0:    temp = $shortrealtobits(float_a + float_b);
            3'd1:    temp = $shortrealtobits(float_a - float_b);
            3'd2:    temp = $shortrealtobits(float_a * float_b);
            3'd3:    temp = $shortrealtobits(float_a / float_b);
            3'd4:    temp = $shortrealtobits($sqrt(float_b));
            default: temp = {1'b0, 8'd0, 23'd0};
        endcase

        // check if the temp result was denormal, if so output zero instead of denormal.
        expected = (~|temp[30:23] & |temp[22:0]) ? {temp[31], 8'd0, 23'd0} : temp;
    endfunction

endmodule

