

module pipelined_fpu_test_synthesis(
    input   logic          clk,
    input   logic          reset,
    input   logic  [2:0]   op,
    input   logic          start,
    input   logic  [31:0]  operand_a,
    input   logic  [31:0]  operand_b,

    output  logic          stall,
    output  logic          valid,
    output  logic  [31:0]  result
    );


    logic  [2:0]   fpu_stage1_op;
    logic          fpu_stage1_start;
    logic  [31:0]  fpu_stage1_operand_a;
    logic  [31:0]  fpu_stage1_operand_b;
    logic          fpu_stage4_valid;
    logic  [31:0]  fpu_stage4_result;


    logic          valid_out;
    logic  [31:0]  result_out;


    always_ff @(posedge clk or posedge reset) begin
        fpu_stage1_op    <= (reset) ? 3'd0 : (stall) ? fpu_stage1_op    : op;
        fpu_stage1_start <= (reset) ? 1'b0 : (stall) ? fpu_stage1_start : start;
        fpu_stage4_valid <= (reset) ? 1'b0 : valid_out;
    end


    always_ff @(posedge clk) begin
        fpu_stage1_operand_a <= (stall) ? fpu_stage1_operand_a : operand_a;
        fpu_stage1_operand_b <= (stall) ? fpu_stage1_operand_b : operand_b;
        fpu_stage4_result    <= result_out;
    end


    pipelined_fpu
    pipelined_fpu(
        .clk,
        .reset,
        .op           (fpu_stage1_op),
        .start        (fpu_stage1_start),
        .operand_a    (fpu_stage1_operand_a),
        .operand_b    (fpu_stage1_operand_b),
        .valid        (valid_out),
        .stall,
        .result       (result_out)
    );


    assign valid  = fpu_stage4_valid;
    assign result = fpu_stage4_result;


endmodule

