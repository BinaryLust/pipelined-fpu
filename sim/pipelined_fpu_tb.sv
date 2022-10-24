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


    integer            seed                  = 3458976;
    integer            cycles_per_test       = 50000; // 50k is equal to the old 10k test size, 1.5M is equal to the old 300k test size
    integer            addition_ops          = 0;
    integer            subtraction_ops       = 0;
    integer            multiplication_ops    = 0;
    integer            division_ops          = 0;
    integer            square_root_ops       = 0;
    integer            float_to_int_ops      = 0;
    integer            int_to_float_ops      = 0;
    integer            absolute_value_ops    = 0;
    integer            total_ops             = 0;
    integer            addition_errors       = 0;
    integer            subtraction_errors    = 0;
    integer            multiplication_errors = 0;
    integer            division_errors       = 0;
    integer            square_root_errors    = 0;
    integer            float_to_int_errors   = 0;
    integer            int_to_float_errors   = 0;
    integer            absolute_value_errors = 0;
    integer            total_errors          = 0;
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
            op              = $urandom_range(3'd0, 3'd7);
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
            op              = $urandom_range(3'd0, 3'd7);
            operand_a       = $urandom();
            operand_b       = $urandom();
            op_queue.push_front(op);
            a_queue.push_front(operand_a);
            b_queue.push_front(operand_b);
        end


        total_ops    = addition_ops + subtraction_ops + multiplication_ops + division_ops + square_root_ops + float_to_int_ops + int_to_float_ops + absolute_value_ops;
        total_errors = addition_errors + subtraction_errors + multiplication_errors + division_errors + square_root_errors + float_to_int_errors + int_to_float_errors + absolute_value_errors;


        // print out total number of errors
        $display("Addition        Ops: %d  Errors: %d", addition_ops,       addition_errors);
        $display("Subtraction     Ops: %d  Errors: %d", subtraction_ops,    subtraction_errors);
        $display("Multiplication  Ops: %d  Errors: %d", multiplication_ops, multiplication_errors);
        $display("Division        Ops: %d  Errors: %d", division_ops,       division_errors);
        $display("Square Root     Ops: %d  Errors: %d", square_root_ops,    square_root_errors);
        $display("Float To Int    Ops: %d  Errors: %d", float_to_int_ops,   float_to_int_errors);
        $display("Int To Float    Ops: %d  Errors: %d", int_to_float_ops,   int_to_float_errors);
        $display("Absolute Value  Ops: %d  Errors: %d", absolute_value_ops, absolute_value_errors);
        $display("Total           Ops: %d  Errors: %d", total_ops,          total_errors);

        $stop;
    end


    always begin
        @(negedge clk)
        if(valid) begin
            operation       = op_queue.pop_back();
            binary_a        = a_queue.pop_back();
            binary_b        = b_queue.pop_back();
            float_a         = $bitstoshortreal(binary_a);
            float_b         = $bitstoshortreal(binary_b);
            float_result    = $bitstoshortreal(result);
            expected_result = expected(operation, binary_a, binary_b);

            // keep track of the total of each type of operation that has completed.
            case(operation)
                3'd0: addition_ops++;
                3'd1: subtraction_ops++;
                3'd2: multiplication_ops++;
                3'd3: division_ops++;
                3'd4: square_root_ops++;
                3'd5: float_to_int_ops++;
                3'd6: int_to_float_ops++;
                3'd7: absolute_value_ops++;
            endcase

            // check for errors and record the total number of them for each operation type.
            if(result != expected_result) begin
                case(operation)
                    3'd0: begin $warning("Result Miss Match on: %.9g + %.9g got: %.9g expected: %.9g",       float_a, float_b, float_result, $bitstoshortreal(expected_result));  addition_errors++;       end
                    3'd1: begin $warning("Result Miss Match on: %.9g - %.9g got: %.9g expected: %.9g",       float_a, float_b, float_result, $bitstoshortreal(expected_result));  subtraction_errors++;    end
                    3'd2: begin $warning("Result Miss Match on: %.9g * %.9g got: %.9g expected: %.9g",       float_a, float_b, float_result, $bitstoshortreal(expected_result));  multiplication_errors++; end
                    3'd3: begin $warning("Result Miss Match on: %.9g / %.9g got: %.9g expected: %.9g",       float_a, float_b, float_result, $bitstoshortreal(expected_result));  division_errors++;       end
                    3'd4: begin $warning("Result Miss Match on: sqrt(%.9g) got: %.9g expected: %.9g",        float_b, float_result, $bitstoshortreal(expected_result));           square_root_errors++;    end
                    3'd5: begin $warning("Result Miss Match on: float_to_int (%.9g) got: %d expected: %d",   float_b, signed'(result), signed'(expected_result));                 float_to_int_errors++;   end
                    3'd6: begin $warning("Result Miss Match on: int_to_float (%d) got: %.9g expected: %.9g", signed'(binary_b), float_result, $bitstoshortreal(expected_result)); int_to_float_errors++;   end
                    3'd7: begin $warning("Result Miss Match on: abs(%.9g) got: %.9g expected: %.9g",         float_b, float_result, $bitstoshortreal(expected_result));           absolute_value_errors++;    end
                endcase

                $display("binary  got      - sign: %b exponent: %b fraction: %b\nbinary  expected - sign: %b exponent: %b fraction: %b",
                             result[31],          result[30:23],          result[22:0],
                    expected_result[31], expected_result[30:23], expected_result[22:0],
                );
                $display("decimal got      - sign: %b exponent: %d fraction: %d\ndecimal expected - sign: %b exponent: %d fraction: %d\n",
                             result[31],          result[30:23],          result[22:0],
                    expected_result[31], expected_result[30:23], expected_result[22:0],
                );
            end
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


    function logic [31:0] expected(logic [2:0] operation, logic [31:0] binary_a, logic[31:0] binary_b);
        logic              a_subnormal;
        logic              b_subnormal;
        logic      [31:0]  bits_a;
        logic      [31:0]  bits_b;
        shortreal          real_a;
        shortreal          real_b;
        logic      [31:0]  temp;


        // check to see if either input is a subnormal value
        a_subnormal = ~|binary_a[30:23] & |binary_a[22:0];
        b_subnormal = ~|binary_b[30:23] & |binary_b[22:0];


        // if the values are subnormal convert them to zero instead
        bits_a = ((operation != 3'd6) & a_subnormal) ? {binary_a[31], 8'd0, 23'd0} : binary_a;
        bits_b = ((operation != 3'd6) & b_subnormal) ? {binary_b[31], 8'd0, 23'd0} : binary_b;


        // produce float values from the bits for later use
        real_a = $bitstoshortreal(bits_a);
        real_b = $bitstoshortreal(bits_b);


        casex(operation)
            3'd0:    temp = $shortrealtobits(real_a + real_b);
            3'd1:    temp = $shortrealtobits(real_a - real_b);
            3'd2:    temp = $shortrealtobits(real_a * real_b);
            3'd3:    temp = $shortrealtobits(real_a / real_b);
            3'd4:    temp = $shortrealtobits($sqrt(real_b));
            3'd5:    temp = shortrealtoint(real_b);
            3'd6:    temp = $shortrealtobits(shortreal'(signed'(bits_b)));
            3'd7:    temp = {1'b0, bits_b[30:0]}; //fabs(real_b);
            //default: temp = {1'b0, 8'd0, 23'd0};
        endcase

        // first check that we aren't doing a float to int conversion then check if the temp result was denormal, if so output zero instead of denormal.
        expected = ((operation != 3'd5) & (~|temp[30:23] & |temp[22:0])) ? {temp[31], 8'd0, 23'd0} : temp;
    endfunction


    function logic [31:0] shortrealtoint(shortreal value);
        logic              [31:0]  binary_value;
        shortreal                  fractional_part;
        logic      signed  [31:0]  integer_part;


        binary_value = $shortrealtobits(value);

        // check for not a number and return minumum possible value if it is a nan.
        if(&binary_value[30:23] & |binary_value[22:0])
            return -32'd2147483648;

        // +/- 2147483584 any float equal to or larger than this value will convert to -2147483648
        // since we are converting from an unsigned fraction to a signed number we must add a leading zero bit
        // before we negate the value, this leads to the max postive value being 7FFFFF80 in hex.
        // which is 2,147,483,520 in decimal. that means a 24-bit fraction with all ones and an
        // exponent of 30 is the largest float that can be converted.
        if((value >= 2147483584.0) || (value <= -2147483584.0))
            return -32'd2147483648;

        integer_part    = $floor(value);
        fractional_part = value - integer_part;

        // make sure value is rounded properly.
        if(fractional_part < 0.5)
            return integer_part;
        if(fractional_part == 0.5)
            return (integer_part[0]) ? (integer_part + 32'd1) : integer_part;
        else
            return integer_part + 32'd1;

    endfunction


    function logic [31:0] fabs(shortreal value);


        if((value < 0.0) | (value == -0.0))
            return $shortrealtobits(-value);
        else
            return $shortrealtobits(value);


    endfunction


endmodule

