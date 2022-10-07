

// this is a restoring divider that just does a check to skip restoring.


// this divider is designed to take 2 normalized mantissas and divide them.
// the only legal format for the operands is as follows 1.xxx...x, the first
// digit must always be a 1.


// if the dividend and divider are normalized fractions with a leading 1
// then the first 23-25 cycles of this do nothing and they can be skipped.


// we could probably use the remainder as a replacement for the sticky bits
// but we compute the guard? and round bits directly.


// this also contains a square root unit that is activated by setting the mode
// bit to 1.


module multi_norm_combined
    #(parameter INWIDTH    = 24,
      parameter OUTWIDTH   = 24,
      parameter REMWIDTH   = (INWIDTH >= OUTWIDTH) ? INWIDTH : OUTWIDTH,
      parameter COUNTWIDTH = $clog2(OUTWIDTH)
    )(
    input   logic                  clk,
    input   logic                  reset,
    input   logic                  mode,
    input   logic                  start,
    input   logic  [INWIDTH-1:0]   dividend_in,
    input   logic  [INWIDTH-1:0]   divisor_radicand_in,

    output  logic                  busy,
    output  logic                  done,
    output  logic  [OUTWIDTH-1:0]  quotient_root,
    output  logic  [REMWIDTH:0]    remainder
    );


    typedef  enum  logic
    {
        IDLE   = 1'd0,
        CALC   = 1'd1
    }   states;


    // registers
    logic   [INWIDTH-1:0]   divisor_radicand;
    states                  state;
    logic   [COUNTWIDTH:0]  count;


    // combinational signals
    logic   [INWIDTH-1:0]   divisor_radicand_next;
    logic                   busy_next;
    logic                   done_next;
    logic   [OUTWIDTH-1:0]  quotient_root_next;
    logic   [REMWIDTH:0]    remainder_next;       // the size of this register is too big if INWIDTH > OUTWIDTH, fix later.
    states                  state_next;
    logic   [COUNTWIDTH:0]  count_next;
    logic   [REMWIDTH+2:0]  shifted_remainder;    // the size of this register is too big if INWIDTH > OUTWIDTH, fix later.
    logic   [REMWIDTH+2:0]  subtracted_remainder; // the size of this register is too big if INWIDTH > OUTWIDTH, fix later.
    logic                   was_negative;


    // register logic
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            divisor_radicand <= {INWIDTH{1'b0}};
            busy             <= 1'b0;
            done             <= 1'b0;
            quotient_root    <= {OUTWIDTH{1'b0}};
            remainder        <= {REMWIDTH+1{1'b0}};
            state            <= IDLE;
            count            <= {COUNTWIDTH+1{1'b0}};
        end else begin
            divisor_radicand <= divisor_radicand_next;
            busy             <= busy_next;
            done             <= done_next;
            quotient_root    <= quotient_root_next;
            remainder        <= remainder_next;
            state            <= state_next;
            count            <= count_next;
        end
    end


    // combinational logic
    always_comb begin
        // defaults
        divisor_radicand_next = divisor_radicand; // retain old value
        busy_next             = 1'b0;             // not busy
        done_next             = 1'b0;             // not done
        quotient_root_next    = quotient_root;    // retain old value
        remainder_next        = remainder;        // retain old value
        state_next            = IDLE;             // return to default state
        count_next            = count;            // retain old value


        // state machine logic
        case(state)
            IDLE:   begin
                        if(start) begin
                            divisor_radicand_next = divisor_radicand_in;        // load divisor
                            busy_next             = 1'b1;                       // set busy
                            count_next            = {{COUNTWIDTH{1'b0}}, 1'b1}; // reset count to 1
                            state_next            = CALC;

                            if(~mode) begin // division
                                quotient_root_next = {dividend_in[0], {OUTWIDTH-1{1'b0}}};                     // load/reset dividend
                                remainder_next     = {{REMWIDTH-(INWIDTH-2){1'b0}}, dividend_in[INWIDTH-1:1]}; // load remainder
                            end else begin  // sqaure root
                                quotient_root_next = {OUTWIDTH{1'b0}};                                         // reset root
                                remainder_next     = {REMWIDTH+1{1'b0}};                                       // reset remainder
                            end
                        end
                    end

            CALC:   begin
                        if(count == OUTWIDTH) begin
                            // done condition
                            done_next  = 1'b1;                               // set done

                            state_next = IDLE;
                        end else begin
                            // normal condition
                            busy_next  = 1'b1;                               // set busy

                            state_next = CALC;
                        end

                        count_next = count + {{COUNTWIDTH{1'b0}}, 1'b1};     // increment count

                        if(was_negative) begin
                            remainder_next     = shifted_remainder[REMWIDTH:0];
                            quotient_root_next = {quotient_root[OUTWIDTH-2:0], 1'b0};
                        end else begin
                            remainder_next     = subtracted_remainder[REMWIDTH:0];
                            quotient_root_next = {quotient_root[OUTWIDTH-2:0], 1'b1};
                        end

                        if(mode) // left shift radicand if we are in square root mode
                            divisor_radicand_next = {divisor_radicand[INWIDTH-3:0], 2'b00};
                    end
        endcase
    end


    // combinational logic
    assign shifted_remainder                   = (mode) ? {remainder[REMWIDTH:0], divisor_radicand[INWIDTH-1:INWIDTH-2]}
                                                        : {remainder[REMWIDTH:0], quotient_root[OUTWIDTH-1]};
    assign {was_negative, subtracted_remainder} = shifted_remainder - ((mode) ? {quotient_root, 2'b01} : divisor_radicand);


endmodule

