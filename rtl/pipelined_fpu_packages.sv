

package operand;

    typedef  enum  logic  [2:0] {
        NORMAL    = 3'b00?,
        ZERO      = 3'b101,
        INFINITE  = 3'b011,
        NAN       = 3'b010,
        SUBNORMAL = 3'b100,
        DONTCARE  = 3'b???
    }   operand_type;

endpackage


package calculation;

    typedef  enum  logic  [2:0] {
        ADD      = 3'd0,
        SUB      = 3'd1,
        MUL      = 3'd2,
        DIV      = 3'd3,
        SQRT     = 3'd4,
        DONTCARE = 3'd?
    } calculation_select;

endpackage


package sign;

    typedef  enum  logic  [3:0] {
        ZERO     = 4'd0,
        ONE      = 4'd1,
        A        = 4'd2,
        B        = 4'd3,
        NB       = 4'd4,
        A_B      = 4'd5,
        A_NB     = 4'd6,
        RESULT   = 4'd7,
        IRESULT  = 4'd8,
        DONTCARE = 4'd?
    }   sign_select;

endpackage


package exponent;

    typedef  enum  logic  [2:0] {
        ZEROS    = 3'd0,
        ONES     = 3'd1,
        A        = 3'd2,
        B        = 3'd3,
        RESULT   = 3'd4,
        IRESULT  = 3'd5,
        DONTCARE = 3'd?
    }   exponent_select;

endpackage


package fraction_msb;

    typedef  enum  logic  [2:0] {
        ZERO     = 3'd0,
        ONE      = 3'd1,
        A        = 3'd2,
        B        = 3'd3,
        RESULT   = 3'd4,
        IRESULT  = 3'd5,
        DONTCARE = 3'd?
    }   fraction_msb_select;

endpackage


package fraction_lsbs;

    typedef  enum  logic  [2:0] {
        ZEROS    = 3'd0,
        A        = 3'd1,
        B        = 3'd2,
        RESULT   = 3'd3,
        IRESULT  = 3'd4,
        DONTCARE = 3'd?
    }   fraction_lsbs_select;

endpackage

