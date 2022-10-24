

module control_logic(
    input   logic                                [2:0]   op,
    input   logic                                        start,
    input   logic                                        operand_sign_a,
    input   logic                                [7:0]   operand_exponent_a,
    input   logic                                [23:0]  operand_fraction_a,
    input   logic                                        operand_sign_b,
    input   logic                                [7:0]   operand_exponent_b,
    input   logic                                [23:0]  operand_fraction_b,
    input   logic                                        aligned_sign_a,
    input   logic                                [7:0]   aligned_exponent_a,
    input   logic                                        aligned_sign_b,
    input   logic                                [7:0]   aligned_exponent_b,

    output  logic                                        remove_bias,
    output  logic                                        exchange_operands,
    output  logic                                [4:0]   align_shift_count,
    output  logic                                        aligned_fraction_a_select,
    output  logic                                        aligned_exponent_b_select,
    output  logic                                        aligned_fraction_b_select,
    output  logic                                        result_sign,
    output  calc1::exponent_select                       calculation_exponent_select,
    output  calc2::fraction_select                       calculation_fraction_select,
    output  logic                                        division_mode,
    output  logic                                        division_op,
    output  logic                                        normal_op,
    output  logic                                        normalize,
    output  logic                                        rounding_mode,
    output  logic                                [1:0]   sticky_bit_select,
    output  sign::sign_select                            sign_select,
    output  exponent::exponent_select                    exponent_select,
    output  fraction_msb::fraction_msb_select            fraction_msb_select,
    output  fraction_lsbs::fraction_lsbs_select          fraction_lsbs_select
    );


    import operand::*;


    operand_type          operand_type_a;
    operand_type          operand_type_b;
    logic                 exponent_all_zeros_a;
    logic                 exponent_all_ones_a;
    logic                 fraction_all_zeros_a;
    logic                 exponent_all_zeros_b;
    logic                 exponent_all_ones_b;
    logic                 fraction_all_zeros_b;
    logic         [8:0]   exponent_difference;
    logic                 exponent_over;
    logic                 exponent_under;


    always_comb begin
        // do checks on exponent and fraction
        exponent_all_zeros_a = ~|operand_exponent_a;
        exponent_all_ones_a  =  &operand_exponent_a;
        fraction_all_zeros_a = ~|operand_fraction_a[22:0];

        exponent_all_zeros_b = ~|operand_exponent_b;
        exponent_all_ones_b  =  &operand_exponent_b;
        fraction_all_zeros_b = ~|operand_fraction_b[22:0];


        // form the bits for the type of each operand
        operand_type_a = operand_type'({exponent_all_zeros_a, exponent_all_ones_a, fraction_all_zeros_a});
        operand_type_b = operand_type'({exponent_all_zeros_b, exponent_all_ones_b, fraction_all_zeros_b});


        // remove bias from exponents unless we are performing an int to float operation, in which case we need to pass the origian exponent values through.
        remove_bias = (op != 3'd6);


        // compare operands to see if we need to exchange them.
        exchange_operands = ((op == 3'd0) | (op == 3'd1)) & ({operand_exponent_a, operand_fraction_a} < {operand_exponent_b, operand_fraction_b});


        // calculate the right shift count for the alignment step
        exponent_difference = ((op == 3'd5) ? 9'd30 : {aligned_exponent_a[7], aligned_exponent_a}) - {aligned_exponent_b[7], aligned_exponent_b};
        case(op)
            3'd0,
            3'd1,
            3'd5:    align_shift_count = (~|exponent_difference[8:5]) ? exponent_difference[4:0] : 5'd31; // for addition, subtraction and float to int. This saturates at the value 31, if any of the upper 4 bits are set.
            3'd4:    align_shift_count = (operand_exponent_b[0]) ? 5'd1 : 5'd0; // for square root. the exponent must be an even number because it has to be divided by 2 (this is to find the square root of the exponent), so we check if it's even and right shift by 1 if it's not.
            default: align_shift_count = 5'd0;
        endcase

        // we can use any of the 3 pieces version of code below to detect if the exponent is out of range for float to int conversion
        //exponent_over  = (signed'(exponent_difference) < signed'(9'd0));                          // exponent difference version
        //exponent_under = (signed'(exponent_difference) > signed'(9'd31));
        //exponent_over  = (signed'({aligned_exponent_b[7], aligned_exponent_b}) > signed'(9'd30)); // aligned exponent version
        //exponent_under = (signed'({aligned_exponent_b[7], aligned_exponent_b}) < signed'(-9'd1));
        exponent_over  = (operand_exponent_b > 8'd157);                                             // raw operand exponent version
        exponent_under = (operand_exponent_b < 8'd126);


        // choose aligned fraction a value
        aligned_fraction_a_select = ((op == 3'd5) | (op == 3'd6) | (op == 3'd7)); // chose all zeros as the fraction value if the op is float to int, int to float, or abs


        // choose aligned exponent b value
        aligned_exponent_b_select = (op == 3'd6); // choose 30 as the exponent if the op is int to float


        // choose aligned fraction b value
        aligned_fraction_b_select = (op == 3'd6); // choose concatenated exponent/fraction value instead of just fraction if op is int to float


        // calculate final sign value
        case(op)
            3'd0:    result_sign = aligned_sign_a;                                         // for add
            3'd1:    result_sign = (exchange_operands) ? ~aligned_sign_a : aligned_sign_a; // for sub
            3'd2,
            3'd3:    result_sign = operand_sign_a ^ operand_sign_b;                        // for mul, div
            3'd4,
            3'd6:    result_sign = aligned_sign_b;                                         // for sqrt, int to float
            default: result_sign = aligned_sign_a;
        endcase


        // select the exponent result for the calculation unit
        casex(op)
            3'd0,
            3'd1:    calculation_exponent_select = calc1::A;
            3'd2:    calculation_exponent_select = calc1::ADD;
            3'd3:    calculation_exponent_select = calc1::SUB;
            3'd4:    calculation_exponent_select = calc1::B_SHR;
            3'd5,
            3'd6,
            3'd7:    calculation_exponent_select = calc1::B;
            default: calculation_exponent_select = calc1::A;
        endcase


        // select the fraction result for the calculation unit
        casex(op)
            3'd0:    calculation_fraction_select = (operand_sign_a  ^ operand_sign_b) ? calc2::SUB : calc2::ADD;
            3'd1:    calculation_fraction_select = (operand_sign_a ~^ operand_sign_b) ? calc2::SUB : calc2::ADD;
            3'd2:    calculation_fraction_select = calc2::MUL;
            3'd3:    calculation_fraction_select = calc2::DIV;
            3'd4:    calculation_fraction_select = calc2::SQRT;
            3'd5,
            3'd6:    calculation_fraction_select = (operand_sign_b) ? calc2::SUB : calc2::ADD;
            3'd7:    calculation_fraction_select = calc2::ADD;
            default: calculation_fraction_select = calc2::ADD;
        endcase


        // select division unit mode, and operation type bits.
        division_mode = 1'b0; division_op = 1'b0; normal_op = 1'b0;                              // set default values
        casex({start, op})
            {1'b1, 3'd0},
            {1'b1, 3'd1},
            {1'b1, 3'd2},
            {1'b1, 3'd5},
            {1'b1, 3'd6},
            {1'b1, 3'd7}: normal_op = 1'b1;                                                      // this is a normal single cycle operation
            {1'b1, 3'd3}: begin division_mode = 1'b0; division_op = 1'b1; end
            {1'b1, 3'd4}: begin division_mode = 1'b1; division_op = 1'b1; end
            default:      begin division_mode = 1'b0; division_op = 1'b0; normal_op = 1'b0; end
        endcase


        // enable normalization if we aren't doing a float to int conversion
        normalize = (op != 3'd5);


        // choose rounding mode
        rounding_mode = (op == 3'd5);


        // choose sticky bits
        casex(op)
            3'd3,
            3'd4:    sticky_bit_select = 2'd1;
            3'd5:    sticky_bit_select = 2'd3;
            default: sticky_bit_select = 2'd0;
        endcase


        // choose final result
        casex({op, operand_type_a, operand_type_b, operand_sign_a, operand_sign_b})
            // 8'b0?0??01? // is_infinite
            {3'd0, INFINITE,  NORMAL,    1'b?, 1'b?},
            {3'd0, NORMAL,    INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // add: +/- infinity
            {3'd0, INFINITE,  INFINITE,  1'b1, 1'b0},
            {3'd0, INFINITE,  INFINITE,  1'b0, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // add: -1.#IND
            {3'd0, INFINITE,  INFINITE,  1'b0, 1'b0},
            {3'd0, INFINITE,  INFINITE,  1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // add: +/- infinity

            {3'd1, INFINITE,  NORMAL,    1'b?, 1'b?},
            {3'd1, NORMAL,    INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // sub: +/- infinity
            {3'd1, INFINITE,  INFINITE,  1'b0, 1'b0},
            {3'd1, INFINITE,  INFINITE,  1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // sub: -1.#IND
            {3'd1, INFINITE,  INFINITE,  1'b0, 1'b1},
            {3'd1, INFINITE,  INFINITE,  1'b1, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // sub: +/- infinity

            {3'd2, INFINITE,  NORMAL,    1'b?, 1'b?},
            {3'd2, NORMAL,    INFINITE,  1'b?, 1'b?},
            {3'd2, INFINITE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // mul: +/- infinity

            {3'd3, INFINITE,  NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // div: +/- infinity
            {3'd3, NORMAL,    INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // div: +/- zero
            {3'd3, INFINITE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // div: -1.#IND

            {3'd4, DONTCARE,  INFINITE,  1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // sqrt: if operand_sign_b is 1 then -1.#IND
            {3'd4, DONTCARE,  INFINITE,  1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // sqrt: if operand_sign_b is 0 then +infinity

            {3'd5, DONTCARE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // float to int: 32'h8000000

            {3'd6, DONTCARE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // int to float: normal result, because this is an integer value and isn't infinite

            {3'd7, DONTCARE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // abs: normal result (it just passes things through and sets the sign to zero)

            // 8'b0?0??10? // is_zero
            {3'd0, NORMAL,    ZERO,      1'b?, 1'b?},
            {3'd0, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::A,      exponent::A,      fraction_msb::A,      fraction_lsbs::A};       // add: a
            {3'd0, ZERO,      NORMAL,    1'b?, 1'b?},
            {3'd0, SUBNORMAL, NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::B,      exponent::B,      fraction_msb::B,      fraction_lsbs::B};       // add: b
            {3'd0, ZERO,      ZERO,      1'b?, 1'b?},
            {3'd0, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {3'd0, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {3'd0, SUBNORMAL, ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::A_B,    exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // add: +/- zero

            {3'd1, NORMAL,    ZERO,      1'b?, 1'b?},
            {3'd1, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::A,      exponent::A,      fraction_msb::A,      fraction_lsbs::A};       // sub: a
            {3'd1, ZERO,      NORMAL,    1'b?, 1'b?},
            {3'd1, SUBNORMAL, NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::NB,     exponent::B,      fraction_msb::B,      fraction_lsbs::B};       // sub: b
            {3'd1, ZERO,      ZERO,      1'b?, 1'b?},
            {3'd1, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {3'd1, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {3'd1, SUBNORMAL, ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::A_NB,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // sub: +/- zero

            {3'd2, NORMAL,    ZERO,      1'b?, 1'b?},
            {3'd2, NORMAL,    SUBNORMAL, 1'b?, 1'b?},
            {3'd2, ZERO,      NORMAL,    1'b?, 1'b?},
            {3'd2, SUBNORMAL, NORMAL,    1'b?, 1'b?},
            {3'd2, ZERO,      ZERO,      1'b?, 1'b?},
            {3'd2, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {3'd2, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {3'd2, SUBNORMAL, ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // mul: +/- zero

            {3'd3, NORMAL,    ZERO,      1'b?, 1'b?},
            {3'd3, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // div: +/- infinity
            {3'd3, ZERO,      NORMAL,    1'b?, 1'b?},
            {3'd3, SUBNORMAL, NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // div: +/- zero
            {3'd3, ZERO,      ZERO,      1'b?, 1'b?},
            {3'd3, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {3'd3, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {3'd3, SUBNORMAL, ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // div: -1.#IND

            {3'd4, DONTCARE,  ZERO,      1'b?, 1'b?},
            {3'd4, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // sqrt: +/- zero

            {3'd5, DONTCARE,  ZERO,      1'b?, 1'b?},
            {3'd5, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // float to int: zero

            {3'd6, DONTCARE,  ZERO,      1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // int to float: zero, if sign b is also zero, because it's the upper bit of the integer
            {3'd6, DONTCARE,  ZERO,      1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // int to float: normal result, if sign b is one
            {3'd6, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // int to float: normal result, because this is an integer value and isn't actually subnormal

            {3'd7, DONTCARE,  ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // abs: normal result (it just passes things through and sets the sign to zero)
            {3'd7, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // abs: turn subnormal number into zero, and set the sign to zero as usual

            // 8'b1?1????? // is_nnan and is_nan
            {3'd0, NAN,       NAN,       1'b0, 1'b1},
            {3'd0, NAN,       NAN,       1'b1, 1'b0},
            {3'd1, NAN,       NAN,       1'b0, 1'b1},
            {3'd1, NAN,       NAN,       1'b1, 1'b0},
            {3'd2, NAN,       NAN,       1'b0, 1'b1},
            {3'd2, NAN,       NAN,       1'b1, 1'b0},
            {3'd3, NAN,       NAN,       1'b0, 1'b1},
            {3'd3, NAN,       NAN,       1'b1, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::A,      exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add, sub, mul, div: NaN

            // 8'b0?0??11? // is_zero and is_infinite
            {3'd0, ZERO,      INFINITE,  1'b?, 1'b?},
            {3'd0, INFINITE,  ZERO,      1'b?, 1'b?},
            {3'd0, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {3'd0, INFINITE,  SUBNORMAL, 1'b?, 1'b?},
            {3'd1, ZERO,      INFINITE,  1'b?, 1'b?},
            {3'd1, INFINITE,  ZERO,      1'b?, 1'b?},
            {3'd1, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {3'd1, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // add, sub: +/- infinity

            {3'd2, ZERO,      INFINITE,  1'b?, 1'b?},
            {3'd2, INFINITE,  ZERO,      1'b?, 1'b?},
            {3'd2, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {3'd2, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // mul: quiet not a number

            {3'd3, ZERO,      INFINITE,  1'b?, 1'b?},
            {3'd3, SUBNORMAL, INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // div: +/- zero
            {3'd3, INFINITE,  ZERO,      1'b?, 1'b?},
            {3'd3, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // div: +/- infinity

            // 8'b0?1????? // is_nan, is_nnan must be zero but doesn't care about anything else.
            {3'd0, NAN,       NAN,       1'b0, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  quiet not a number (following x86 standards)
            {3'd0, NORMAL,    NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // add:  quiet not a number (following x86 standards)
            {3'd0, NAN,       NORMAL,    1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  quiet not a number (following x86 standards)
            {3'd0, ZERO,      NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // add:  quiet not a number (following x86 standards)
            {3'd0, NAN,       ZERO,      1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  quiet not a number (following x86 standards)
            {3'd0, INFINITE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // add:  quiet not a number (following x86 standards)
            {3'd0, NAN,       INFINITE,  1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  quiet not a number (following x86 standards)
            {3'd0, SUBNORMAL, NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // add:  quiet not a number (following x86 standards)
            {3'd0, NAN,       SUBNORMAL, 1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  quiet not a number (following x86 standards)

            {3'd1, NAN,       NAN,       1'b0, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NORMAL,    NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NAN,       NORMAL,    1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  quiet not a number (following x86 standards)
            {3'd1, ZERO,      NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NAN,       ZERO,      1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  quiet not a number (following x86 standards)
            {3'd1, INFINITE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NAN,       INFINITE,  1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  quiet not a number (following x86 standards)
            {3'd1, SUBNORMAL, NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sub:  quiet not a number (following x86 standards)
            {3'd1, NAN,       SUBNORMAL, 1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  quiet not a number (following x86 standards)

            {3'd2, NAN,       NAN,       1'b0, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NORMAL,    NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NAN,       NORMAL,    1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  quiet not a number (following x86 standards)
            {3'd2, ZERO,      NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NAN,       ZERO,      1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  quiet not a number (following x86 standards)
            {3'd2, INFINITE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NAN,       INFINITE,  1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  quiet not a number (following x86 standards)
            {3'd2, SUBNORMAL, NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // mul:  quiet not a number (following x86 standards)
            {3'd2, NAN,       SUBNORMAL, 1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  quiet not a number (following x86 standards)

            {3'd3, NAN,       NAN,       1'b0, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  quiet not a number (following x86 standards)
            {3'd3, NORMAL,    NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // div:  quiet not a number (following x86 standards)
            {3'd3, NAN,       NORMAL,    1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  quiet not a number (following x86 standards)
            {3'd3, ZERO,      NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // div:  quiet not a number (following x86 standards)
            {3'd3, NAN,       ZERO,      1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  quiet not a number (following x86 standards)
            {3'd3, INFINITE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // div:  quiet not a number (following x86 standards)
            {3'd3, NAN,       INFINITE,  1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  quiet not a number (following x86 standards)
            {3'd3, SUBNORMAL, NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // div:  quiet not a number (following x86 standards)
            {3'd3, NAN,       SUBNORMAL, 1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  quiet not a number (following x86 standards)

            {3'd4, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sqrt: quiet not a number (following x86 standards)

            {3'd5, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // float to int: in systemverilog it should return 0 but in C code it should return 32'h8000000

            {3'd6, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // int to float: normal result, because this is an integer value and isn't a nan at all

            {3'd7, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // abs: normal result (it just passes things through and sets the sign to zero)

            // 8'b1?0????? // is_nnan, is_nan must be zero but doesn't care about anything else.
            {3'd0, NAN,       NAN,       1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NORMAL,    NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NAN,       NORMAL,    1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, ZERO,      NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NAN,       ZERO,      1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, INFINITE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NAN,       INFINITE,  1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, SUBNORMAL, NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // add:  negative quiet not a number (following x86 standards)
            {3'd0, NAN,       SUBNORMAL, 1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // add:  negative quiet not a number (following x86 standards)

            {3'd1, NAN,       NAN,       1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NORMAL,    NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NAN,       NORMAL,    1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, ZERO,      NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NAN,       ZERO,      1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, INFINITE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NAN,       INFINITE,  1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, SUBNORMAL, NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sub:  negative quiet not a number (following x86 standards)
            {3'd1, NAN,       SUBNORMAL, 1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // sub:  negative quiet not a number (following x86 standards)

            {3'd2, NAN,       NAN,       1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NORMAL,    NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NAN,       NORMAL,    1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, ZERO,      NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NAN,       ZERO,      1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, INFINITE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NAN,       INFINITE,  1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, SUBNORMAL, NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // mul:  negative quiet not a number (following x86 standards)
            {3'd2, NAN,       SUBNORMAL, 1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // mul:  negative quiet not a number (following x86 standards)

            {3'd3, NAN,       NAN,       1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NORMAL,    NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NAN,       NORMAL,    1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, ZERO,      NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NAN,       ZERO,      1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, INFINITE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NAN,       INFINITE,  1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, SUBNORMAL, NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // div:  negative quiet not a number (following x86 standards)
            {3'd3, NAN,       SUBNORMAL, 1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A};       // div:  negative quiet not a number (following x86 standards)

            {3'd4, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B};       // sqrt: negative quiet not a number (following x86 standards)

            {3'd5, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // float to int: in systemverilog it should return 0 but in C code it should return 32'h8000000

            {3'd6, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // int to float: normal result, because this is an integer value and isn't a nan at all

            {3'd7, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // abs: normal result (it just passes things through and sets the sign to zero)

            // normal results
            {3'd0, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // add:  normal result
            {3'd1, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // sub:  normal result
            {3'd2, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // mult: normal result
            {3'd3, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // div:  normal result
            {3'd4, DONTCARE,  NORMAL,    1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // sqrt: operand_sign_b == 0 then normal result
            {3'd4, DONTCARE,  NORMAL,    1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // sqrt: operand_sign_b == 1 then -1.#IND

            {3'd5, DONTCARE,  NORMAL,    1'b?, 1'b?}: if(exponent_over)
                                                          {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ZEROS,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};  // float to int: exponent too big
                                                      else if(exponent_under)
                                                          {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ZEROS,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};  // float to int: exponent too small
                                                      else
                                                          {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::IRESULT, exponent::IRESULT, fraction_msb::IRESULT, fraction_lsbs::IRESULT};   // float to int: normal result

            {3'd6, DONTCARE,  NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // int to float: normal result

            {3'd7, DONTCARE,  NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // abs: normal result (it just passes things through and sets the sign to zero)

            default:                                  {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // zero
        endcase
    end


endmodule

