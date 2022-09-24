
// general algorithm below

// root      = 0
// remainder = 0
// count     = 0

// do {
//     remainder      = (remainder << 2) | radicand[31:30];
//     partial_root   = (root << 2) | 2'b01;
//     radicand       = radicand << 2;
//     if(remainder - partial_root) >= 0)
//         root       = (root << 1) | 1'b1;
//         remainder  = (remainder - partial_root);
//     else
//         root       = (root << 1) | 1'b0;
// } loop


// this is a restoring square rooter that just does a check to skip restoring.


module multi_norm_sqrt
    #(parameter INWIDTH    = 24,
      parameter OUTWIDTH   = 24,
      parameter COUNTWIDTH = $clog2(OUTWIDTH)
    )(
    input   logic                  clk,
    input   logic                  reset,
    input   logic                  start,
    input   logic  [INWIDTH-1:0]   radicand_in,

    output  logic                  busy,
    output  logic                  done,
    output  logic  [OUTWIDTH-1:0]  root,
    output  logic  [OUTWIDTH:0]    remainder
    );


    typedef  enum  logic
    {
        IDLE   = 1'd0,
        CALC   = 1'd1
    }   states;


    // registers
    logic   [INWIDTH-1:0]   radicand;
    states                  state;
    logic   [COUNTWIDTH:0]  count;


    // combinational signals
    logic   [INWIDTH-1:0]   radicand_next;
    logic                   busy_next;
    logic                   done_next;
    logic   [OUTWIDTH-1:0]  root_next;
    logic   [OUTWIDTH:0]    remainder_next;
    states                  state_next;
    logic   [COUNTWIDTH:0]  count_next;
    logic   [OUTWIDTH+2:0]  shifted_remainder;
    logic   [OUTWIDTH+2:0]  subtracted_remainder;
    logic                   was_negative;


    // register logic
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            radicand  <= {INWIDTH{1'b0}};
            busy      <= 1'b0;
            done      <= 1'b0;
            root      <= {OUTWIDTH{1'b0}};
            remainder <= {OUTWIDTH+1{1'b0}};
            state     <= IDLE;
            count     <= {COUNTWIDTH+1{1'b0}};
        end else begin
            radicand  <= radicand_next;
            busy      <= busy_next;
            done      <= done_next;
            root      <= root_next;
            remainder <= remainder_next;
            state     <= state_next;
            count     <= count_next;
        end
    end


    // combinational logic
    always_comb begin
        // defaults
        radicand_next   = radicand;  // retain old value
        busy_next       = 1'b0;      // no error
        done_next       = 1'b0;      // no error
        root_next       = root;      // retain old value
        remainder_next  = remainder; // retain old value
        state_next      = IDLE;      // return to default state
        count_next      = count;     // retain old value


        // state machine logic
        case(state)
            IDLE:   begin
                        if(start) begin
                            // normal condition
                            radicand_next  = radicand_in;                // load radicand
                            root_next      = {OUTWIDTH{1'b0}};           // reset root
                            remainder_next = {OUTWIDTH+1{1'b0}};         // reset remainder
                            busy_next      = 1'b1;                       // set busy
                            count_next     = {{COUNTWIDTH{1'b0}}, 1'b1}; // reset count to 1
                            state_next     = CALC;
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
                            remainder_next = shifted_remainder[OUTWIDTH:0];
                            root_next      = {root[OUTWIDTH-2:0], 1'b0};
                        end else begin
                            remainder_next = subtracted_remainder[OUTWIDTH:0];
                            root_next      = {root[OUTWIDTH-2:0], 1'b1};
                        end

                        // left shift radicand, this must be a shift so that zeros fill the register incase we need
                        // more bits than there are in the register do to the output being variable width. Another
                        // way to do it would be to always make the radicand register 2x bigger than OUTWIDTH.
                        radicand_next      = {radicand[INWIDTH-3:0], 2'b00};
                    end
        endcase
    end


    // combinational logic
    assign shifted_remainder                    = {remainder[OUTWIDTH:0], radicand[INWIDTH-1:INWIDTH-2]};
    assign {was_negative, subtracted_remainder} = shifted_remainder - {root, 2'b01};


endmodule

