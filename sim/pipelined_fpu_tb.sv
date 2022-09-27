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
    logic [31:0] a;
    logic [31:0] b;


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
        .op,
        .start,
        .a,
        .b,
        .done,
        .busy,
        .result
    );


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* testing variables                                                                                                                                     */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    integer            seed               = 37388;
    integer            errors             = 0;
    shortreal          float_a;
    shortreal          float_b;
    shortreal          float_result;
    logic      [31:0]  expected_result;


    /*********************************************************************************************************************************************************/
    /*                                                                                                                                                       */
    /* test stimulus                                                                                                                                         */
    /*                                                                                                                                                       */
    /*********************************************************************************************************************************************************/


    // set initial values
    initial begin
        reset = 1'b0;
        op    = 3'd3;
        start = 1'b0;
        a     = 32'd0;
        b     = 32'd0;
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


        // run the constrained random test for square root
        repeat(100000) begin
            @(posedge clk)
            op              = 3'd3;
            start           = 1'b1;
            a               = rand_float();

            @(posedge clk);
            start           = 1'b0;

            @(posedge done);
            @(negedge clk)
            float_a         = $bitstoshortreal(a);
            float_result    = $bitstoshortreal(result);
            expected_result = expected();

            if(result != expected_result) begin
                $warning("Result Miss Match on: sqrt(%.9g) got: %.9g expected: %.9g",
                    float_a,
                    float_result,
                    $bitstoshortreal(expected_result)
                );
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


        // run a completely random test for square root
        repeat(100000) begin
            @(posedge clk)
            op              = 3'd3;
            start           = 1'b1;
            a               = $urandom();

            @(posedge clk);
            start           = 1'b0;

            @(posedge done);
            @(negedge clk)
            float_a         = $bitstoshortreal(a);
            float_result    = $bitstoshortreal(result);
            expected_result = expected();

            if(result != expected_result) begin
                $warning("Result Miss Match on: sqrt(%.9g) got: %.9g expected: %.9g",
                    float_a,
                    float_result,
                    $bitstoshortreal(expected_result)
                );
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


        // run the constrained random test for multiplication
        repeat(100000) begin
            @(posedge clk)
            op              = 3'd1;
            a               = rand_float();
            b               = rand_float();
 
            @(negedge clk)
            float_a         = $bitstoshortreal(a);
            float_b         = $bitstoshortreal(b);
            float_result    = $bitstoshortreal(result);
            expected_result = expected();
 
            if(result != expected_result) begin
                $warning("Result Miss Match on: %.9g * %.9g got: %.9g expected: %.9g",
                    float_a,
                    float_b,
                    float_result,
                    $bitstoshortreal(expected_result)
                );
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
 

        // run a completely random test for multiplication
        repeat(100000) begin
            @(posedge clk)
            op              = 3'd1;
            a               = $urandom();
            b               = $urandom();
 
            @(negedge clk)
            float_a         = $bitstoshortreal(a);
            float_b         = $bitstoshortreal(b);
            float_result    = $bitstoshortreal(result);
            expected_result = expected();
 
            if(result != expected_result) begin
                $warning("Result Miss Match on: %.9g * %.9g got: %.9g expected: %.9g",
                    float_a,
                    float_b,
                    float_result,
                    $bitstoshortreal(expected_result)
                );
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


        // run the constrained random test for division
        repeat(10000) begin
            @(posedge clk)
            op              = 3'd2;
            start           = 1'b1;
            a               = rand_float();
            b               = rand_float();
 
            @(posedge clk);
            start           = 1'b0;
 
            @(posedge done);
            @(negedge clk)
            float_a         = $bitstoshortreal(a);
            float_b         = $bitstoshortreal(b);
            float_result    = $bitstoshortreal(result);
            expected_result = expected();
 
            if(result != expected_result) begin
                $warning("Result Miss Match on: %.9g / %.9g got: %.9g expected: %.9g",
                    float_a,
                    float_b,
                    float_result,
                    $bitstoshortreal(expected_result)
                );
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
 
        // run a completely random test for division
        repeat(10000) begin
            @(posedge clk)
            op              = 3'd2;
            start           = 1'b1;
            a               = $urandom();
            b               = $urandom();
 
            @(posedge clk);
            start           = 1'b0;
 
            @(posedge done);
            @(negedge clk)
            float_a         = $bitstoshortreal(a);
            float_b         = $bitstoshortreal(b);
            float_result    = $bitstoshortreal(result);
            expected_result = expected();
 
            if(result != expected_result) begin
                $warning("Result Miss Match on: %.9g / %.9g got: %.9g expected: %.9g",
                    float_a,
                    float_b,
                    float_result,
                    $bitstoshortreal(expected_result)
                );
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


    function logic [31:0] expected();
        automatic logic          a_sign      = a[31];
        automatic logic  [7:0]   a_exponent  = a[30:23];
        automatic logic  [22:0]  a_fraction  = a[22:0];

        automatic logic          b_sign      = b[31];
        automatic logic  [7:0]   b_exponent  = b[30:23];
        automatic logic  [22:0]  b_fraction  = b[22:0];

        automatic logic  a_zero      = ~|a_exponent  & ~|a_fraction;
        automatic logic  b_zero      = ~|b_exponent  & ~|b_fraction;
        automatic logic  a_inf       = &a_exponent   & ~|a_fraction;
        automatic logic  b_inf       = &b_exponent   & ~|b_fraction;
        automatic logic  a_nan       = &a_exponent   & |a_fraction;
        automatic logic  b_nan       = &b_exponent   & |b_fraction;
        automatic logic  a_denorm    = ~|a_exponent  & |a_fraction;
        automatic logic  b_denorm    = ~|b_exponent  & |b_fraction;

        automatic logic  zero        = a_zero | b_zero;
        automatic logic  inf         = a_inf  | b_inf;
        automatic logic  nan         = (~a_sign & a_nan) | (~b_sign & b_nan);
        automatic logic  nnan        = (a_sign  & a_nan) | (b_sign  & b_nan);
        automatic logic  signal      = ~a_fraction[22] | ~b_fraction[22];
        automatic logic  denorm      = a_denorm | b_denorm;

        automatic logic  [31:0]  temp;

        casex(op)
            // multiplication
            3'd1:       begin
                            casex({nan, nnan, inf, zero | denorm})
                                4'b10??: temp = {1'b0, 8'd255, 1'b1, (a_nan) ? a_fraction[21:0] : b_fraction[21:0]}; // quiet not a number (following x86 standards)
                                4'b01??: temp = {1'b1, 8'd255, 1'b1, (a_nan) ? a_fraction[21:0] : b_fraction[21:0]}; // negative quiet not a number (following x86 standards)
                                4'b??01: temp = {a[31] ^ b[31], 8'd0, 23'd0};
                                4'b??11: temp = {1'b1, 8'd255, 23'b10000000000000000000000};
                                default: temp = $shortrealtobits(float_a * float_b);
                            endcase
                        end

            // division
            3'd2:    begin
                        casex({nan, nnan, inf, zero | denorm})
                        4'b10??:    temp = {1'b0, 8'd255, 1'b1, (a_nan) ? a_fraction[21:0] : b_fraction[21:0]}; // quiet not a number (following x86 standards)
                        4'b01??:    temp = {1'b1, 8'd255, 1'b1, (a_nan) ? a_fraction[21:0] : b_fraction[21:0]}; // negative quiet not a number (following x86 standards)
                        4'b??01:    begin
                                        case({a_zero, b_zero})
                                        2'b01:      temp = {a[31] ^ b[31], 8'd255, 23'd0};                      // div: +/- infinity
                                        2'b11:      temp = {1'b1, 8'd255, 1'b1, 22'd0};                         // div: -1.#IND
                                        default:    temp = {a[31] ^ b[31], 8'b0, 23'b0};                        // div: +/- zero
                                        endcase
                                    end
                        4'b??11:    temp = (a_zero & b_inf) ? {a[31] ^ b[31], 8'b0,   23'b0}                    // div: +/- zero
                                                            : {a[31] ^ b[31], 8'd255, 23'd0};                   // div: +/- infinity
                        default:    temp = $shortrealtobits(float_a / float_b);
                        endcase
                    end

            // square root
            3'd3:    temp = (a_zero | a_denorm) ? {a[31], 8'd0, 23'd0} : $shortrealtobits($sqrt(float_a)); // if input is denormal we expect 0 as the result, otherwise we expect the square root of the input.

            default: temp = {1'b0, 8'd0, 23'd0};
        endcase

        // check if the temp result was denormal, if so output zero instead of denormal.
        expected = (~|temp[30:23] & |temp[22:0]) ? {temp[31], 8'd0, 23'd0} : temp;
    endfunction

endmodule

