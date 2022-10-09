

module control_logic(
    input   logic                                [2:0]   op,
    input   logic                                        start,
    input   logic                                        sign_a,
    input   logic                                [7:0]   exponent_a,
    input   logic                                [23:0]  fraction_a,
    input   logic                                        sign_b,
    input   logic                                [7:0]   exponent_b,
    input   logic                                [23:0]  fraction_b,
    input   logic                                        sorted_sign_a,
    input   logic                                [7:0]   sorted_exponent_a,
    input   logic                                        sorted_sign_b,
    input   logic                                [7:0]   sorted_exponent_b,

    output  logic                                        exchange_operands,
    output  logic                                [4:0]   align_shift_count,
    output  logic                                        result_sign,
    output  calculation::calculation_select              calculation_select,
    output  logic                                        divider_mode,
    output  logic                                        divider_start,
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
    logic         [7:0]   exponent_difference;


    always_comb begin
        // do checks on exponent and fraction
        exponent_all_zeros_a = ~|exponent_a;
        exponent_all_ones_a  =  &exponent_a;
        fraction_all_zeros_a = ~|fraction_a[22:0];

        exponent_all_zeros_b = ~|exponent_b;
        exponent_all_ones_b  =  &exponent_b;
        fraction_all_zeros_b = ~|fraction_b[22:0];


        // form the bits for the type of each operand
        operand_type_a = operand_type'({exponent_all_zeros_a, exponent_all_ones_a, fraction_all_zeros_a});
        operand_type_b = operand_type'({exponent_all_zeros_b, exponent_all_ones_b, fraction_all_zeros_b});


        // compare operands to see if we need to exchange them.
        exchange_operands = ((op == 3'd0) | (op == 3'd1)) & ({exponent_a, fraction_a} < {exponent_b, fraction_b});


        // calculate the right shift count for the alignment step
        exponent_difference = sorted_exponent_a - sorted_exponent_b;
        case(op)
            3'd0,
            3'd1:    align_shift_count = (~|exponent_difference[7:5]) ? exponent_difference[4:0] : 5'd31; // for addition and subtraction, this checks to make sure the upper 3 bits of the difference are zero, if that is so then the difference is 31 or less and it is used.
            3'd4:    align_shift_count = (sorted_exponent_b[0]) ? 5'd1 : 5'd0; // for square root. the exponent must be an even number because it has to be divided by 2 (this is to find the square root of the exponent), so we check if it's even and right shift by 1 if it's not.
            default: align_shift_count = 5'd0;
        endcase


        // calculate final sign value
        case(op)
            3'd0:    result_sign = sorted_sign_a;                                        // for add
            3'd1:    result_sign = (exchange_operands) ? ~sorted_sign_a : sorted_sign_a; // for sub
            default: result_sign = sign_a ^ sign_b;                                      // for mul, div
        endcase


        // select the type of calculation that will take place
        casex(op)
            3'd0:    calculation_select = (sign_a  ^ sign_b) ? calculation::SUB : calculation::ADD;
            3'd1:    calculation_select = (sign_a ~^ sign_b) ? calculation::SUB : calculation::ADD;
            3'd2:    calculation_select = calculation::MUL;
            3'd3:    calculation_select = calculation::DIV;
            3'd4:    calculation_select = calculation::SQRT;
            default: calculation_select = calculation::ADD;
        endcase


        // select division unit mode and starting conditions
        divider_mode  = (op == 3'd4);                      // if op type is square root then set divider_mode to 1
        divider_start = (op == 3'd3 | op == 3'd4) & start; // if optype is divide or square root and start line is high then enable divider unit.


        // choose final result
        casex({op, operand_type_a, operand_type_b, sign_a, sign_b})
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

            {3'd4, DONTCARE,  INFINITE,  1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // sqrt: if sign_a is 1 then -1.#IND
            {3'd4, DONTCARE,  INFINITE,  1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // sqrt: if sign_a is 0 then +infinity

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
            {3'd4, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::B,      exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // sqrt: +/- zero

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

            // normal results
            {3'd0, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // add:  normal result
            {3'd1, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // sub:  normal result
            {3'd2, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // mult: normal result
            {3'd3, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // div:  normal result
            {3'd4, DONTCARE,  NORMAL,    1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT};  // sqrt: sign_a == 0 then normal result
            {3'd4, DONTCARE,  NORMAL,    1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS};   // sqrt: sign_a == 1 then -1.#IND

            default:                                  {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS};   // zero
        endcase
    end


endmodule

