

module control_logic(
    input   logic                                [3:0]   op,
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
    output  logic                                        check_result,
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
        remove_bias = (op != 4'd6);


        // compare operands to see if we need to exchange them.
        exchange_operands = ((op == 4'd0) | (op == 4'd1)) & ({operand_exponent_a, operand_fraction_a} < {operand_exponent_b, operand_fraction_b});


        // calculate the right shift count for the alignment step
        exponent_difference = ((op == 4'd5) ? 9'd30 : {aligned_exponent_a[7], aligned_exponent_a}) - {aligned_exponent_b[7], aligned_exponent_b};
        case(op)
            4'd0,
            4'd1,
            4'd5:    align_shift_count = (~|exponent_difference[8:5]) ? exponent_difference[4:0] : 5'd31; // for addition, subtraction and float to int. This saturates at the value 31, if any of the upper 4 bits are set.
            4'd4:    align_shift_count = (operand_exponent_b[0]) ? 5'd1 : 5'd0; // for square root. the exponent must be an even number because it has to be divided by 2 (this is to find the square root of the exponent), so we check if it's even and right shift by 1 if it's not.
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
        aligned_fraction_a_select = ((op == 4'd5) | (op == 4'd6) | (op == 4'd7) | (op == 4'd8)); // chose all zeros as the fraction value if the op is float to int, int to float, or abs


        // choose aligned exponent b value
        aligned_exponent_b_select = (op == 4'd6); // choose 30 as the exponent if the op is int to float


        // choose aligned fraction b value
        aligned_fraction_b_select = (op == 4'd6); // choose concatenated exponent/fraction value instead of just fraction if op is int to float


        // calculate final sign value
        case(op)
            4'd0:    result_sign = aligned_sign_a;                                         // for add
            4'd1:    result_sign = (exchange_operands) ? ~aligned_sign_a : aligned_sign_a; // for sub
            4'd2,
            4'd3:    result_sign = operand_sign_a ^ operand_sign_b;                        // for mul, div
            4'd4,
            4'd6:    result_sign = aligned_sign_b;                                         // for sqrt, int to float
            4'd8:    result_sign = ~aligned_sign_b;                                        // for neg
            default: result_sign = aligned_sign_a;
        endcase


        // select the exponent result for the calculation unit
        casex(op)
            4'd0,
            4'd1:    calculation_exponent_select = calc1::A;
            4'd2:    calculation_exponent_select = calc1::ADD;
            4'd3:    calculation_exponent_select = calc1::SUB;
            4'd4:    calculation_exponent_select = calc1::B_SHR;
            4'd5,
            4'd6,
            4'd7,
            4'd8:    calculation_exponent_select = calc1::B;
            default: calculation_exponent_select = calc1::A;
        endcase


        // select the fraction result for the calculation unit
        casex(op)
            4'd0:    calculation_fraction_select = (operand_sign_a  ^ operand_sign_b) ? calc2::SUB : calc2::ADD;
            4'd1:    calculation_fraction_select = (operand_sign_a ~^ operand_sign_b) ? calc2::SUB : calc2::ADD;
            4'd2:    calculation_fraction_select = calc2::MUL;
            4'd3:    calculation_fraction_select = calc2::DIV;
            4'd4:    calculation_fraction_select = calc2::SQRT;
            4'd5,
            4'd6:    calculation_fraction_select = (operand_sign_b) ? calc2::SUB : calc2::ADD;
            4'd7,
            4'd8:    calculation_fraction_select = calc2::ADD;
            default: calculation_fraction_select = calc2::ADD;
        endcase


        // select division unit mode, and operation type bits.
        division_mode = 1'b0; division_op = 1'b0; normal_op = 1'b0;                              // set default values
        casex({start, op})
            {1'b1, 4'd0},
            {1'b1, 4'd1},
            {1'b1, 4'd2},
            {1'b1, 4'd5},
            {1'b1, 4'd6},
            {1'b1, 4'd7},
            {1'b1, 4'd8}: normal_op = 1'b1;                                                      // this is a normal single cycle operation
            {1'b1, 4'd3}: begin division_mode = 1'b0; division_op = 1'b1; end
            {1'b1, 4'd4}: begin division_mode = 1'b1; division_op = 1'b1; end
            default:      begin division_mode = 1'b0; division_op = 1'b0; normal_op = 1'b0; end
        endcase


        // enable normalization if we aren't doing a float to int conversion
        normalize = (op != 4'd5);


        // choose rounding mode
        rounding_mode = (op == 4'd5);


        // choose sticky bits
        casex(op)
            4'd3,
            4'd4:    sticky_bit_select = 2'd1;
            4'd5:    sticky_bit_select = 2'd3;
            default: sticky_bit_select = 2'd0;
        endcase


        // choose final result
        casex({op, operand_type_a, operand_type_b, operand_sign_a, operand_sign_b})
            // 8'b0?0??01? // is_infinite
            {4'd0, INFINITE,  NORMAL,    1'b?, 1'b?},
            {4'd0, NORMAL,    INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // add: +/- infinity
            {4'd0, INFINITE,  INFINITE,  1'b1, 1'b0},
            {4'd0, INFINITE,  INFINITE,  1'b0, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS,  1'b0};  // add: -1.#IND
            {4'd0, INFINITE,  INFINITE,  1'b0, 1'b0},
            {4'd0, INFINITE,  INFINITE,  1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // add: +/- infinity

            {4'd1, INFINITE,  NORMAL,    1'b?, 1'b?},
            {4'd1, NORMAL,    INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // sub: +/- infinity
            {4'd1, INFINITE,  INFINITE,  1'b0, 1'b0},
            {4'd1, INFINITE,  INFINITE,  1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS,  1'b0};  // sub: -1.#IND
            {4'd1, INFINITE,  INFINITE,  1'b0, 1'b1},
            {4'd1, INFINITE,  INFINITE,  1'b1, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // sub: +/- infinity

            {4'd2, INFINITE,  NORMAL,    1'b?, 1'b?},
            {4'd2, NORMAL,    INFINITE,  1'b?, 1'b?},
            {4'd2, INFINITE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // mul: +/- infinity

            {4'd3, INFINITE,  NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // div: +/- infinity
            {4'd3, NORMAL,    INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // div: +/- zero
            {4'd3, INFINITE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS,  1'b0};  // div: -1.#IND

            {4'd4, DONTCARE,  INFINITE,  1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS,  1'b0};  // sqrt: if operand_sign_b is 1 then -1.#IND
            {4'd4, DONTCARE,  INFINITE,  1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // sqrt: if operand_sign_b is 0 then +infinity

            {4'd5, DONTCARE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // float to int: 32'h8000000

            {4'd6, DONTCARE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // int to float: normal result, because this is an integer value and isn't infinite

            {4'd7, DONTCARE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // abs: normal result (it just passes things through and sets the sign to zero)

            {4'd8, DONTCARE,  INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // neg: normal result (it just passes things through and inverts the sign)

            // 8'b0?0??10? // is_zero
            {4'd0, NORMAL,    ZERO,      1'b?, 1'b?},
            {4'd0, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::A,      exponent::A,      fraction_msb::A,      fraction_lsbs::A,      1'b0};  // add: a
            {4'd0, ZERO,      NORMAL,    1'b?, 1'b?},
            {4'd0, SUBNORMAL, NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::B,      exponent::B,      fraction_msb::B,      fraction_lsbs::B,      1'b0};  // add: b
            {4'd0, ZERO,      ZERO,      1'b?, 1'b?},
            {4'd0, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {4'd0, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {4'd0, SUBNORMAL, ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::A_B,    exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // add: +/- zero

            {4'd1, NORMAL,    ZERO,      1'b?, 1'b?},
            {4'd1, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::A,      exponent::A,      fraction_msb::A,      fraction_lsbs::A,      1'b0};  // sub: a
            {4'd1, ZERO,      NORMAL,    1'b?, 1'b?},
            {4'd1, SUBNORMAL, NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::NB,     exponent::B,      fraction_msb::B,      fraction_lsbs::B,      1'b0};  // sub: b
            {4'd1, ZERO,      ZERO,      1'b?, 1'b?},
            {4'd1, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {4'd1, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {4'd1, SUBNORMAL, ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::A_NB,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // sub: +/- zero

            {4'd2, NORMAL,    ZERO,      1'b?, 1'b?},
            {4'd2, NORMAL,    SUBNORMAL, 1'b?, 1'b?},
            {4'd2, ZERO,      NORMAL,    1'b?, 1'b?},
            {4'd2, SUBNORMAL, NORMAL,    1'b?, 1'b?},
            {4'd2, ZERO,      ZERO,      1'b?, 1'b?},
            {4'd2, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {4'd2, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {4'd2, SUBNORMAL, ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // mul: +/- zero

            {4'd3, NORMAL,    ZERO,      1'b?, 1'b?},
            {4'd3, NORMAL,    SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // div: +/- infinity
            {4'd3, ZERO,      NORMAL,    1'b?, 1'b?},
            {4'd3, SUBNORMAL, NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // div: +/- zero
            {4'd3, ZERO,      ZERO,      1'b?, 1'b?},
            {4'd3, SUBNORMAL, SUBNORMAL, 1'b?, 1'b?},
            {4'd3, ZERO,      SUBNORMAL, 1'b?, 1'b?},
            {4'd3, SUBNORMAL, ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS,  1'b0};  // div: -1.#IND

            {4'd4, DONTCARE,  ZERO,      1'b?, 1'b?},
            {4'd4, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // sqrt: +/- zero

            {4'd5, DONTCARE,  ZERO,      1'b?, 1'b?},
            {4'd5, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // float to int: zero

            {4'd6, DONTCARE,  ZERO,      1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // int to float: zero, if sign b is also zero, because it's the upper bit of the integer
            {4'd6, DONTCARE,  ZERO,      1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // int to float: normal result, if sign b is one
            {4'd6, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // int to float: normal result, because this is an integer value and isn't actually subnormal

            {4'd7, DONTCARE,  ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // abs: normal result (it just passes things through and sets the sign to zero)
            {4'd7, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // abs: turns subnormal number into zero, then set the sign bit to zero

            {4'd8, DONTCARE,  ZERO,      1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // neg: normal result (it just passes things through and inverts the sign)
            {4'd8, DONTCARE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // neg: turns subnormal number into zero, then inverts the sign bit

            // 8'b1?1????? // is_nnan and is_nan
            {4'd0, NAN,       NAN,       1'b0, 1'b1},
            {4'd0, NAN,       NAN,       1'b1, 1'b0},
            {4'd1, NAN,       NAN,       1'b0, 1'b1},
            {4'd1, NAN,       NAN,       1'b1, 1'b0},
            {4'd2, NAN,       NAN,       1'b0, 1'b1},
            {4'd2, NAN,       NAN,       1'b1, 1'b0},
            {4'd3, NAN,       NAN,       1'b0, 1'b1},
            {4'd3, NAN,       NAN,       1'b1, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::A,      exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add, sub, mul, div: NaN

            // 8'b0?0??11? // is_zero and is_infinite
            {4'd0, ZERO,      INFINITE,  1'b?, 1'b?},
            {4'd0, INFINITE,  ZERO,      1'b?, 1'b?},
            {4'd0, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {4'd0, INFINITE,  SUBNORMAL, 1'b?, 1'b?},
            {4'd1, ZERO,      INFINITE,  1'b?, 1'b?},
            {4'd1, INFINITE,  ZERO,      1'b?, 1'b?},
            {4'd1, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {4'd1, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // add, sub: +/- infinity

            {4'd2, ZERO,      INFINITE,  1'b?, 1'b?},
            {4'd2, INFINITE,  ZERO,      1'b?, 1'b?},
            {4'd2, SUBNORMAL, INFINITE,  1'b?, 1'b?},
            {4'd2, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS,  1'b0};  // mul: quiet not a number

            {4'd3, ZERO,      INFINITE,  1'b?, 1'b?},
            {4'd3, SUBNORMAL, INFINITE,  1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // div: +/- zero
            {4'd3, INFINITE,  ZERO,      1'b?, 1'b?},
            {4'd3, INFINITE,  SUBNORMAL, 1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::ONES,   fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // div: +/- infinity

            // 8'b0?1????? // is_nan, is_nnan must be zero but doesn't care about anything else.
            {4'd0, NAN,       NAN,       1'b0, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  quiet not a number (following x86 standards)
            {4'd0, NORMAL,    NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // add:  quiet not a number (following x86 standards)
            {4'd0, NAN,       NORMAL,    1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  quiet not a number (following x86 standards)
            {4'd0, ZERO,      NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // add:  quiet not a number (following x86 standards)
            {4'd0, NAN,       ZERO,      1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  quiet not a number (following x86 standards)
            {4'd0, INFINITE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // add:  quiet not a number (following x86 standards)
            {4'd0, NAN,       INFINITE,  1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  quiet not a number (following x86 standards)
            {4'd0, SUBNORMAL, NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // add:  quiet not a number (following x86 standards)
            {4'd0, NAN,       SUBNORMAL, 1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  quiet not a number (following x86 standards)

            {4'd1, NAN,       NAN,       1'b0, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  quiet not a number (following x86 standards)
            {4'd1, NORMAL,    NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sub:  quiet not a number (following x86 standards)
            {4'd1, NAN,       NORMAL,    1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  quiet not a number (following x86 standards)
            {4'd1, ZERO,      NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sub:  quiet not a number (following x86 standards)
            {4'd1, NAN,       ZERO,      1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  quiet not a number (following x86 standards)
            {4'd1, INFINITE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sub:  quiet not a number (following x86 standards)
            {4'd1, NAN,       INFINITE,  1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  quiet not a number (following x86 standards)
            {4'd1, SUBNORMAL, NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sub:  quiet not a number (following x86 standards)
            {4'd1, NAN,       SUBNORMAL, 1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  quiet not a number (following x86 standards)

            {4'd2, NAN,       NAN,       1'b0, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  quiet not a number (following x86 standards)
            {4'd2, NORMAL,    NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // mul:  quiet not a number (following x86 standards)
            {4'd2, NAN,       NORMAL,    1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  quiet not a number (following x86 standards)
            {4'd2, ZERO,      NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // mul:  quiet not a number (following x86 standards)
            {4'd2, NAN,       ZERO,      1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  quiet not a number (following x86 standards)
            {4'd2, INFINITE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // mul:  quiet not a number (following x86 standards)
            {4'd2, NAN,       INFINITE,  1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  quiet not a number (following x86 standards)
            {4'd2, SUBNORMAL, NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // mul:  quiet not a number (following x86 standards)
            {4'd2, NAN,       SUBNORMAL, 1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  quiet not a number (following x86 standards)

            {4'd3, NAN,       NAN,       1'b0, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  quiet not a number (following x86 standards)
            {4'd3, NORMAL,    NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // div:  quiet not a number (following x86 standards)
            {4'd3, NAN,       NORMAL,    1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  quiet not a number (following x86 standards)
            {4'd3, ZERO,      NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // div:  quiet not a number (following x86 standards)
            {4'd3, NAN,       ZERO,      1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  quiet not a number (following x86 standards)
            {4'd3, INFINITE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // div:  quiet not a number (following x86 standards)
            {4'd3, NAN,       INFINITE,  1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  quiet not a number (following x86 standards)
            {4'd3, SUBNORMAL, NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // div:  quiet not a number (following x86 standards)
            {4'd3, NAN,       SUBNORMAL, 1'b0, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  quiet not a number (following x86 standards)

            {4'd4, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sqrt: quiet not a number (following x86 standards)

            {4'd5, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // float to int: in systemverilog it should return 0 but in C code it should return 32'h8000000

            {4'd6, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // int to float: normal result, because this is an integer value and isn't a nan at all

            {4'd7, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // abs: normal result (it just passes things through and sets the sign to zero)

            {4'd8, DONTCARE,  NAN,       1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // neg: normal result (it just passes things through and inverts the sign)

            // 8'b1?0????? // is_nnan, is_nan must be zero but doesn't care about anything else.
            {4'd0, NAN,       NAN,       1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  negative quiet not a number (following x86 standards)
            {4'd0, NORMAL,    NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // add:  negative quiet not a number (following x86 standards)
            {4'd0, NAN,       NORMAL,    1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  negative quiet not a number (following x86 standards)
            {4'd0, ZERO,      NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // add:  negative quiet not a number (following x86 standards)
            {4'd0, NAN,       ZERO,      1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  negative quiet not a number (following x86 standards)
            {4'd0, INFINITE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // add:  negative quiet not a number (following x86 standards)
            {4'd0, NAN,       INFINITE,  1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  negative quiet not a number (following x86 standards)
            {4'd0, SUBNORMAL, NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // add:  negative quiet not a number (following x86 standards)
            {4'd0, NAN,       SUBNORMAL, 1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // add:  negative quiet not a number (following x86 standards)

            {4'd1, NAN,       NAN,       1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  negative quiet not a number (following x86 standards)
            {4'd1, NORMAL,    NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sub:  negative quiet not a number (following x86 standards)
            {4'd1, NAN,       NORMAL,    1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  negative quiet not a number (following x86 standards)
            {4'd1, ZERO,      NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sub:  negative quiet not a number (following x86 standards)
            {4'd1, NAN,       ZERO,      1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  negative quiet not a number (following x86 standards)
            {4'd1, INFINITE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sub:  negative quiet not a number (following x86 standards)
            {4'd1, NAN,       INFINITE,  1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  negative quiet not a number (following x86 standards)
            {4'd1, SUBNORMAL, NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sub:  negative quiet not a number (following x86 standards)
            {4'd1, NAN,       SUBNORMAL, 1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // sub:  negative quiet not a number (following x86 standards)

            {4'd2, NAN,       NAN,       1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  negative quiet not a number (following x86 standards)
            {4'd2, NORMAL,    NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // mul:  negative quiet not a number (following x86 standards)
            {4'd2, NAN,       NORMAL,    1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  negative quiet not a number (following x86 standards)
            {4'd2, ZERO,      NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // mul:  negative quiet not a number (following x86 standards)
            {4'd2, NAN,       ZERO,      1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  negative quiet not a number (following x86 standards)
            {4'd2, INFINITE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // mul:  negative quiet not a number (following x86 standards)
            {4'd2, NAN,       INFINITE,  1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  negative quiet not a number (following x86 standards)
            {4'd2, SUBNORMAL, NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // mul:  negative quiet not a number (following x86 standards)
            {4'd2, NAN,       SUBNORMAL, 1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // mul:  negative quiet not a number (following x86 standards)

            {4'd3, NAN,       NAN,       1'b1, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  negative quiet not a number (following x86 standards)
            {4'd3, NORMAL,    NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // div:  negative quiet not a number (following x86 standards)
            {4'd3, NAN,       NORMAL,    1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  negative quiet not a number (following x86 standards)
            {4'd3, ZERO,      NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // div:  negative quiet not a number (following x86 standards)
            {4'd3, NAN,       ZERO,      1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  negative quiet not a number (following x86 standards)
            {4'd3, INFINITE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // div:  negative quiet not a number (following x86 standards)
            {4'd3, NAN,       INFINITE,  1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  negative quiet not a number (following x86 standards)
            {4'd3, SUBNORMAL, NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // div:  negative quiet not a number (following x86 standards)
            {4'd3, NAN,       SUBNORMAL, 1'b1, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::A,      1'b0};  // div:  negative quiet not a number (following x86 standards)

            {4'd4, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::B,      1'b0};  // sqrt: negative quiet not a number (following x86 standards)

            {4'd5, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};  // float to int: in systemverilog it should return 0 but in C code it should return 32'h8000000

            {4'd6, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // int to float: normal result, because this is an integer value and isn't a nan at all

            {4'd7, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // abs: normal result (it just passes things through and sets the sign to zero)

            {4'd8, DONTCARE,  NAN,       1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // neg: normal result (it just passes things through and inverts the sign)

            // normal results
            {4'd0, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b1};  // add:  normal result
            {4'd1, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b1};  // sub:  normal result
            {4'd2, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b1};  // mult: normal result
            {4'd3, NORMAL,    NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b1};  // div:  normal result
            {4'd4, DONTCARE,  NORMAL,    1'b?, 1'b0}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b1};  // sqrt: operand_sign_b == 0 then normal result
            {4'd4, DONTCARE,  NORMAL,    1'b?, 1'b1}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ONES,   fraction_msb::ONE,    fraction_lsbs::ZEROS,  1'b0};  // sqrt: operand_sign_b == 1 then -1.#IND

                                                      // move this to the result control logic later and change the check result line to multiple bits to specify not only if we should check but what type of check to do
            {4'd5, DONTCARE,  NORMAL,    1'b?, 1'b?}: if(exponent_over)
                                                          {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ONE,    exponent::ZEROS,   fraction_msb::ZERO,   fraction_lsbs::ZEROS, 1'b0};  // float to int: exponent too big
                                                      else if(exponent_under)
                                                          {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ZEROS,   fraction_msb::ZERO,   fraction_lsbs::ZEROS, 1'b0};  // float to int: exponent too small
                                                      else
                                                          {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::IRESULT, exponent::IRESULT, fraction_msb::IRESULT, fraction_lsbs::IRESULT, 1'b0};   // float to int: normal result

            {4'd6, DONTCARE,  NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // int to float: normal result

            {4'd7, DONTCARE,  NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // abs: normal result (it just passes things through and sets the sign to zero)

            {4'd8, DONTCARE,  NORMAL,    1'b?, 1'b?}: {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::RESULT, exponent::RESULT, fraction_msb::RESULT, fraction_lsbs::RESULT, 1'b0};  // neg: normal result (it just passes things through and inverts the sign)

            default:                                  {sign_select, exponent_select, fraction_msb_select, fraction_lsbs_select, check_result} = {sign::ZERO,   exponent::ZEROS,  fraction_msb::ZERO,   fraction_lsbs::ZEROS,  1'b0};   // zero
        endcase
    end


endmodule

