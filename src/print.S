.include "src/parse.S"

/* ======================================================
 * print a single character using the write syscall
 * parameter:
 *  rdi => pointer to character
 */
print_char:
    movq %rdi, %rsi /* msg argument of write syscall */
    movq $0x01, %rax /* write syscall */
    movq $0x01, %rdi /* write to stdout */
    movq $0x01, %rdx /* length to write (1) */
    syscall
    retq

/* ======================================================
 * print a '\n' using the write syscall
 */
linebreak:
    movl $0x0A, %r8d
    leaq (%r8), %rdi
    callq print_char
    retq

/* ======================================================
 * print a '0'.
 */
print_zero:
    movl $0x30, %eax
    movl %eax, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq print_char
    retq

/* ======================================================
 * print a '.' using the write syscall
 */
print_floating_point:
    movl $0x2E, %eax
    movl %eax, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq print_char
    retq

/* =====================================================
 * Print the specified amount of zeros.
 *
 * parameter:
 *  edi => loop exit condition
 */
print_zeros:
.Lprint_zeros_loop:
    pushq %rdi
    callq print_zero
    popq %rdi
    subl $1, %edi
    cmpl $0, %edi
    jne .Lprint_zeros_loop
    retq


/* =====================================================
 * Prepend 0's as the result of mantissa * 10^exponent is
 * smaller than 1/-1.
 *
 * parameter:
 *  edi => difference between number of digits and the sum of
 *         the exponent and the number of digits.
 */
 prepend_zeros:
    subl $1, %edi
    pushq %rdi
    callq print_zero
    callq print_floating_point
    popq %rdi
    cmpl $0, %edi
    jbe .Lprepend_zeros_return
    callq print_zeros
.Lprepend_zeros_return:
    retq

/* =====================================================
 * Append 0's as the result of mantissa * 10^exponent is
 * greater than the original mantissa.
 *
 * parameter:
 *  edi => difference between number of digits and the sum of
 *         the exponent and the number of digits.
 */
append_zeros:
    imull $-1, %edi
    callq print_zeros
    retq

/* =====================================================
 * Get the number of digits in a number
 *
 * As long as the given integer is greater than zero, assign the quotient
 * of the division: given integer / 10 to itself.
 *
 * parameter:
 *  integer => rdi
 */
get_number_of_digits:
    pushq %rbx
    xorq %r8, %r8

    /* idivl requires edx:eax as the dividend, zero edx and sign extend the number */
    xorl %eax, %eax
    movq %rdi, %rax
    movl $10, %ebx
.Lget_number_of_digits_loop:
    cqto
    idivl %ebx
    incq %r8
    cmpl $0, %eax
    ja .Lget_number_of_digits_loop
    movl %r8d, %eax
    nop
    popq %rbx
    retq

/* ======================================================
 * Compute the logarithm base 10 of 2 ^ number, rounded down.
 * Use the forumla provided by the RYU algorithm.
 * (github.com/ulfjack/ryu/blob/d4114cedf9de3a9504e0fc21e212ef1043af64c7/ryu/common.h)
 *
 * works for 0 <= input <= 1650
 *
 * parameter:
 *  rdi => adj. exponent
 *
 * return:
 *  rax => result
 */
log10pow2:
    imull $78913, %edi
    sarl $18, %edi
    movl %edi, %eax
    retq

/* ======================================================
 * Compute the logarithm base 2 of 5 ^ number, rounded up.
 * Use the forumla provided by the RYU algorithm.
 * (github.com/ulfjack/ryu/blob/d4114cedf9de3a9504e0fc21e212ef1043af64c7/ryu/common.h)
 *
 * works for 0 <= input <= 3528
 *
 * parameter:
 *  rdi => Index for the factor table
 *
 * return:
 *  rax => result
 */
pow5bits:
    imull $1217359, %edi
    sarl $19, %edi
    incl %edi
    movl %edi, %eax
    retq

/* ======================================================
 * Compute the logarithm base 10 of 5 ^ number, rounded down.
 * Use the forumla provided by the RYU algorithm.
 * (github.com/ulfjack/ryu/blob/d4114cedf9de3a9504e0fc21e212ef1043af64c7/ryu/common.h)
 *
 * works for 0 < input < 2620
 *
 * parameter:
 *  rdi => adj. exponent
 *
 * return:
 *  rax => result
 */
log10pow5:
    imull $732923, %edi
    sarl $20, %edi
    movl %edi, %eax
    retq

/* ======================================================
 * print a string until the null terminator
 * parameter:
 *  rdi => pointer to the first character
 */
print_str:
    pushq %rbp
    movq %rdi, %rbp
.loop:
    movzbl (%rbp), %eax
    testb %al, %al
    je .print_success
    movq %rbp, %rdi
    callq print_char
    addq $0x01, %rbp
    jmp .loop

.print_success:
    movl $0, %eax
    nop
    popq %rbp
    retq

/* ======================================================
 * Print a number, by acquiring the number of digits and then
 * dividing it by 10^x, where x is the number of digits - 1.
 * This step is done repeteadely, while reducing x with each cycle.
 *
 * parameter:
 *  rdi => Number
 *  rsi => exponent of the number
 *  rdx => sign bit of the number
 *
 * Note: currently works with < 64bit numbers
 */
print_number:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    /* R8 = number of digits
     * R9 = original input number
     * R10 = integer part of division */
    xorq %r12, %r12 /* current loop cycle zero indexed */
     /* R13 = number of digits + exponent
      * R14 = register for preserving the original number of digits */

    cmpl $0, %edx
    je .Lprint_number_digit_amount
    movl $0x2d, %eax
    movl %eax, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq print_char
.Lprint_number_digit_amount:
    callq get_number_of_digits
    movq %rax, %r8
    movq %r8, %r13
    movq %r8, %r14
    addl %esi, %r13d
    movq %rdi, %r9
    cmpl %r13d, %r8d
    jle .Lprint_number_loop
    movl %r8d, %edi
    subl %r13d, %edi
    callq prepend_zeros
.Lprint_number_loop:
    cmpl $0, %r12d
    je .Lprint_get_power_of_10
    cmpl %r12d, %r13d
    jne .Lprint_get_power_of_10
    callq print_floating_point
.Lprint_get_power_of_10:
    decq %r8
    // preserve the original number of digits to deny jumping into append_zeros
    movq $10, %rdi
    movq %r8, %rsi
    callq power
    movl %eax, %ebx
    xorl %eax, %eax
    movl %r9d, %eax
    cqto
    idivl %ebx
    movq %rax, %r10
    addl $0x30, %eax
    movl %eax, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq print_char
    /* Subtract the digit[r10] * 10^(r8)[ebx] from the number[r9] */
    imul %ebx, %r10d
    subq %r10, %r9

    incl %r12d
    cmpq $0, %r8
    ja .Lprint_number_loop
    cmpl %r13d, %r14d
    jge .Lprint_number_return
    movl %r14d, %edi
    subl %r13d, %edi
    callq append_zeros
.Lprint_number_return:
    movl $0x0A, %eax
    movl %eax, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq print_char
    nop
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * Split the IEEE754 floating-point number into it's sub parts:
 * Sign bit, exponent and mantissa.
 *
 * parameter:
 *  rdi => pointer to structure:
 *      +0 => sign bit
 *      +4 => exponent
 *      +8 => mantissa
 *
 * parameter:
 *  xmm0 => input floating-point number
 */
split_into_parts:
    pushq %rbp
    movq %rsp, %rbp
    vmovss %xmm0, -8(%rbp)
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    /* 1. sign bit */
    sarl $31, %eax
    movzbl %al, %eax
    movl %eax, (%rdi)
    /* 2. exponent */
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    /* mantissa bits = 23*/
    sarl $23, %eax
    /* (1 << exponent bits(8)) - 1 = 255*/
    andl $255, %eax
    movl %eax, 4(%rdi)
    /* 3. mantissa */
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    movl .LMantissa_mask, %ebx
    andl %ebx, %eax
    movl %eax, 8(%rdi)
    movq %rbp, %rsp
    popq %rbp
    retq
.LMantissa_mask:
    /* (1 << mantissa bits(23)) -1 */
    .long 8388607

/* ======================================================
 * Check if the number is equal to zero.
 *
 * parameter:
 *  rdi => pointer to structure:
 *      +0 => sign bit
 *      +4 => exponent
 *      +8 => mantissa
 *
 * return:
 *  rax => 1 (True is zero) | 0 (False is not zero)
 */
zero_check:
    pushq %rbp
    movq %rsp, %rbp
    movl 8(%rdi), %eax
    cmpq $0, %rax
    jne .Lisnotzero
    movl 4(%rdi), %eax
    cmpq $0, %rax
    jne .Lisnotzero
    movq $1, %rax
    jmp .Lzero_check_return
.Lisnotzero:
    movq $0, %rax
.Lzero_check_return:
    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * Adjust sub parts of the floating point number to prepare
 * the number for the conversion to an unsigned integer.
 * That involves moving the decimal 'dot' to the rightmost
 * position.
 *
 * parameter:
 *  rdi => pointer to structure:
 *      +0  => sign bit
 *      +4  => exponent
 *      +8  => mantissa
 *      +12 => adjusted exponent
 *      +16 => adjusted mantissa
 */
adjust_parts:
    pushq %rbp
    movq %rsp, %rbp
    movl 4(%rdi), %eax
    cmpl $0, %eax
    je .Ladjust_with_exponent_0
    /*subtract Bias(127), Mantissa len(23) & Bits for bounds computation(2)*/
    subl $152, %eax
    movl %eax, 12(%rdi)
    movl 8(%rdi), %eax
    movl $1, %ebx
    sall $23, %ebx
    orl %ebx, %eax
    movl %eax, 16(%rdi)
    jmp .Ladjust_return
.Ladjust_with_exponent_0:
    /* exponent = 1 - Bias - mantissa len - bits for bounds computation */
    movl $-151, 12(%rdi)
    movl 8(%rdi), %eax
    movl %eax, 16(%rdi)
.Ladjust_return:
    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * Determine the interval of valid outputs, by computing
 * the halfway points to the next larger and smaller floating point number.
 *
 * parameter:
 *  rdi => pointer to structure:
 *      +0  => sign bit
 *      +4  => exponent
 *      +8  => mantissa
 *      +12 => adjusted exponent
 *      +16 => adjusted mantissa
 *      +20 => lower bound output interval
 *      +24 => middle of output interval
 *      +28 => upper bound output interval
 */
compute_output_interval:
    pushq %rbp
    movq %rsp, %rbp

    movl 16(%rdi), %r8d
    movl %r8d, %eax
    imull $4, %eax
    movl %eax, 24(%rdi)
    movl %eax, %ebx
    addl $2, %ebx
    movl %ebx, 28(%rdi)
    subl $1, %eax
    movl 4(%rdi), %ebx
    cmpl $0, %ebx
    jne .Llow_shift_compute_interval
    movl 4(%rdi), %ecx
    cmpl $1, %ecx
    jle .Llow_shift_compute_interval
    jmp .Lcompute_interval_return
.Llow_shift_compute_interval:
    subl $1, %eax
.Lcompute_interval_return:
    movl %eax, 20(%rdi)

    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * Scale the output interval value up by the given factor
 * and shift it to the right by the given shift value - 32.
 * The result is interval of possible integer output values.
 *
 * parameter:
 *  edi => output interval value (lower bound/mid/upper bound)
 *  rsi => factor from the factor table
 *  edx => shift value
 *
 * return:
 *  eax => The shifted sum of the interval values multiplied with
 *         a high and low factor
 */
scale_and_shift_output_interval:
    movl %edx, %r10d

    movl %edi, %eax
    movl %esi, %edx
    /* (64bit)mantissa x (32bit)factor */
    imulq %rdx, %rax
    movq %rax, %r8
    movl %edi, %eax
    shrq $32, %rsi
    movl %esi, %edx
    /* (64bit)mantissa x (32bit)(factor >> 32) */
    imulq %rdx, %rax
    movq %rax, %r9
    shrq $32, %r8
    addq %r9, %r8
    subl $32, %r10d
    movl %r10d, %ecx
    shrq %cl, %r8
    movl %r8d, %eax
    retq

/* ======================================================
 * Convert every value of the output interval into integers.
 * Use 64-bit arithmetic and use different steps, when the adjusted
 * exponent is bigger than 0 (eg. if the input exponent is >= 2^153).
 *
 * The general forumula is:
 *  result = ((a >> 32) + b) >> (c - 32)
 *  where:
 *  [adjusted exponent >= 0]
 *      a = (64bit)Mantissa * factor_array[log10(2^exponent)]
 *      b = (64bit)Mantissa * (factor_array[log10(2^exponent)] >> 32)
 *      c = exponent * -1 + (32bit)log10(2^exponent) + 59
 *        + ceil(log2(5^(32bit)log10(2^exponent))) -1
 *  [adjusted exponent < 0]
 *      a = (64bit)Mantissa * factor_array[factor_index]
 *      b = (32bit)((64bit)Mantissa * (factor_array[factor_index] >> 32))
 *      c = (32bit)exponent - ceil(log2(5^b)) - 61
 *      factor_index = (exponent * -1) - (32bit)log10(5^(-1 * exponent))
 *
 * ** NOTE :
 *  simplified version, only works correctly for ~96% of possible inputs **
 *
 * parameter:
 *  rdi => pointer to structure:
 *      +0  => sign bit
 *      +4  => exponent
 *      +8  => mantissa
 *      +12 => adjusted exponent
 *      +16 => adjusted mantissa
 *      +20 => lower bound output interval
 *      +24 => middle of output interval
 *      +28 => upper bound output interval
 *      +32 => lower bound interval conversion
 *      +36 => middle of interval conversion
 *      +40 => upper bound of interval conversion
 */
convert_output_interval:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12 /* Factor index */
    pushq %r13 /* Factor index case < 0 */
    pushq %r14 /* Shift value */
    pushq %r15 /* Factor */
    xorq %r12, %r12
    movl 12(%rdi), %eax
    cmpl $0, %eax
    jl .Lconvert_with_sub_zero_exponent
    /* adjusted exponent >= 0:
     * prepare factor array index & shift value */
    pushq %rdi
    movl %eax, %edi
    callq log10pow2
    popq %rdi
    movl %eax, %r12d
    movl %r12d, %r14d
    movl 12(%rdi), %eax
    imull $-1, %eax
    addl %eax, %r14d
    addl $59, %r14d
    pushq %rdi
    movl %r12d, %edi
    callq pow5bits
    popq %rdi
    addl %eax, %r14d
    subl $1, %r14d
    /* Get the factor from the factor array */
    leaq FLOAT_POW5_INV_SPLIT(%rip), %rax
    leaq 0x0(,%r12,8), %r12
    movq (%r12, %rax), %rax
    movq %rax, %r15
    jmp .Lperform_conversion
.Lconvert_with_sub_zero_exponent:
    /* adjusted exponent < 0:
     * prepare factor array index & shift value */
    imull $-1, %eax
    pushq %rdi
    movq %rdi, %r8
    movl %eax, %edi
    callq log10pow5
    popq %rdi
    movl %eax, %r12d
    movl 12(%rdi), %eax
    imull $-1, %eax
    subl %r12d, %eax
    movl %eax, %r13d
    pushq %rdi
    movl %r13d, %edi
    callq pow5bits
    popq %rdi
    subl $61, %eax
    movl %r12d, %r14d
    subl %eax, %r14d
    /* Get the factor from the factor array */
    leaq FLOAT_POW5_SPLIT(%rip), %rax
    leaq 0x0(,%r13,8), %r13
    movq (%r13, %rax), %rax
    movq %rax, %r15
.Lperform_conversion:
    /* lower bound of output interval */
    pushq %rdi
    movl 20(%rdi), %edi
    movq %r15, %rsi
    movl %r14d, %edx
    callq scale_and_shift_output_interval
    popq %rdi
    movl %eax, 32(%rdi)
    /* mid of output interval */
    pushq %rdi
    movl 24(%rdi), %edi
    movq %r15, %rsi
    movl %r14d, %edx
    callq scale_and_shift_output_interval
    popq %rdi
    movl %eax, 36(%rdi)
    /* upper bound of output interval */
    pushq %rdi
    movl 28(%rdi), %edi
    movq %r15, %rsi
    movl %r14d, %edx
    callq scale_and_shift_output_interval
    popq %rdi
    movl %eax, 40(%rdi)

.Lconvert_result:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * Calculate the final Exponent with:
 * [adjusted exponent >= 0]:
 *      floor(log10(2^adjusted exponent)) + number of removed digits
 * [adjusted exponent < 0]:
 *      floor(log10(5^-(adjusted exponent))) + adjusted exponent
 *      + number of removed digits
 *
 * parameter:
 *  edi => adjusted exponent
 *  esi => number of removed digits
 *
 * return:
 *  eax => exponent
 */
calculate_final_exponent:
    cmpl $0, %edi
    jl .Lfinal_exponent_with_sub_zero_exponent
    callq log10pow2
    addl %esi, %eax
    jmp .Lfinal_exponent_return
.Lfinal_exponent_with_sub_zero_exponent:
    movl %edi, %ebx
    imull $-1, %edi
    callq log10pow5
    addl %ebx, %eax
    addl %esi, %eax
.Lfinal_exponent_return:
    retq

/* ======================================================
 * Find the shortest decimal representation within
 * the interval of possible outputs.
 * General procedure:
 * Divide the whole output interval by 10 for as long as
 * the upper boundary is greater as the lower boundary.
 * Count the amount of removed digits and get the correct exponent
 * with a call to calculate_final_exponent.
 * The mantissa is calculated by taking the middle of the interval,
 * as soon as the loop condition is false and adding 1, whenever
 * the remainder of the previous division is greater than 5 or
 * when the middle of the interval is equal to the bottom of the interval.
 *
 * NOTE: This is the simple implementation, which fits 96% of the cases
 * according to the algorithm author. Which means that this algorithm fails
 * to compute an accurate result for ~4% of the numbers.
 *
 * parameter:
 *  rdi => pointer to structure:
 *      +0  => sign bit
 *      +4  => exponent
 *      +8  => mantissa
 *      +12 => adjusted exponent
 *      +16 => adjusted mantissa
 *      +20 => lower bound output interval
 *      +24 => middle of output interval
 *      +28 => upper bound output interval
 *      +32 => lower bound interval conversion
 *      +36 => middle of interval conversion
 *      +40 => upper bound of interval conversion
 *
 * return:
 *  eax => result mantissa
 *  edx => result exponent
 */
find_shortest_representation:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12 /* amount of removed digits */

    movl 32(%rdi), %r8d
    movl 36(%rdi), %r9d
    movl 40(%rdi), %r10d
    xorq %r12, %r12
.Lfind_representation_loop:
    movl $10, %ebx
    movl %r8d, %eax
    cqto
    idivl %ebx
    movl %eax, %r8d
    movl %r9d, %eax
    cqto
    idivl %ebx
    movl %eax, %r9d
    movb %dl, %r11b
    movl %r10d, %eax
    cqto
    idivl %ebx
    movl %eax, %r10d
    incl %r12d
    movl %r10d, %eax
    cqto
    idivl %ebx
    movl %eax, %ecx
    movl %r8d, %eax
    cqto
    idivl %ebx
    subl %eax, %ecx
    cmpl $0, %ecx
    jg .Lfind_representation_loop
    pushq %rdi
    movl 12(%rdi), %edi
    movl %r12d, %esi
    callq calculate_final_exponent
    popq %rdi
    movl %eax, %edx
    movl %r9d, %eax
    cmpl %r9d, %r8d
    je .Lfind_representation_increase_output
    cmpl $5, %r11d
    jge .Lfind_representation_increase_output
    jmp .Lfind_representation_return
.Lfind_representation_increase_output:
    incl %eax
.Lfind_representation_return:
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * convert a IEEE754 floating-point number to a string and
 * print each character.
 *
 * parameter:
 *  xmm0 => input floating-point number
 */
print_float:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12 /* sign bit */
    leaq -160(%rbp), %rdi
    callq split_into_parts
    movl (%rdi), %r12d
    callq zero_check
    cmpq $1, %rax
    je .Lprint_zero
    callq adjust_parts
    callq compute_output_interval
    callq convert_output_interval
    callq find_shortest_representation
    movl %eax, %edi
    movl %edx, %esi
    movl %r12d, %edx
    callq print_number
    jmp .Lprint_float_return
.Lprint_zero:
    movq $0, %rdi
    movq $0, %rsi
    movq $0, %rdx
    callq print_number
.Lprint_float_return:
    popq %r12
    movq %rbp, %rsp
    popq %rbp
    retq
