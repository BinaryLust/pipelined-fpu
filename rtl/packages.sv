

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


package sign;

    typedef  enum  logic  [2:0] {
        ZERO     = 3'd0,
        ONE      = 3'd1,
        A        = 3'd2,
        B        = 3'd3,
        NB       = 3'd4,
        A_B      = 3'd5,
        A_NB     = 3'd6,
        RESULT   = 3'd7,
        DONTCARE = 3'd?
    }   sign_select;

endpackage


package exponent;

    typedef  enum  logic  [2:0] {
        ZEROS    = 3'd0,
        ONES     = 3'd1,
        A        = 3'd2,
        B        = 3'd3,
        RESULT   = 3'd4,
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
        DONTCARE = 3'd?
    }   fraction_msb_select;

endpackage


package fraction_lsbs;

    typedef  enum  logic  [1:0] {
        ZEROS    = 2'd0,
        A        = 2'd1,
        B        = 2'd2,
        RESULT   = 2'd3,
        DONTCARE = 2'd?
    }   fraction_lsbs_select;

endpackage

