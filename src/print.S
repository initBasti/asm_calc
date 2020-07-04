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
 * print a '.' using the write syscall
 */
print_floating_point:
    pushq %r8
    movl $0x2E, %r8d
    leaq (%r8), %rdi
    callq print_char
    popq %r8
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
 * print a integer
 * parameter:
 *  rdi => integer
 *
 * Note: currently works with < 64bit numbers
 */
print_int:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r8
    pushq %r9
    pushq %r10
    xorq %r8, %r8
    xorq %r9, %r9
    xorq %r10, %r10

    callq get_number_of_digits
    movl %eax, %r8d
    movq %rdi, %r9
.Lprint_int_loop:
    decq %r8
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

    cmpq $0, %r8
    ja .Lprint_int_loop

    nop
    popq %r10
    popq %r9
    popq %r8
    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * Split the IEEE754 floating-point number into it's sub parts:
 * Sign bit, exponent and mantissa.
 *
 * Stack map:
 *  -80 => sign bit
 *  -84 => exponent
 *  -88 => mantissa
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
    movl %eax, -80(%rbp)
    /* 2. exponent */
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    /* mantissa bits = 23*/
    sarl $23, %eax
    /* (1 << exponent bits(8)) - 1 = 255*/
    andl $255, %eax
    movl %eax, -84(%rbp)
    /* 3. mantissa */
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    movl .LMantissa_mask, %ebx
    andl %ebx, %eax
    movl %eax, -88(%rbp)
    movq %rbp, %rsp
    popq %rbp
    retq
.LMantissa_mask:
    /* (1 << mantissa bits(23)) -1 */
    .long 8388607

/* ======================================================
 * Check if the number is equal to zero.
 *
 * Stack map:
 *  -80 => sign bit
 *  -84 => exponent
 *  -88 => mantissa
 *
 * return:
 *  rax => 1 (True is zero) | 0 (False is not zero)
 */
zero_check:
    pushq %rbp
    movq %rsp, %rbp
    movl -88(%rbp), %eax
    cmpq $0, %rax
    jne .Lisnotzero
    movl -84(%rbp), %eax
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
 * Stack map:
 *  -84 => exponent
 *  -88 => mantissa
 *  -92 => adj. exponent
 *  -96 => adj. mantissa
 */
adjust_parts:
    pushq %rbp
    movq %rsp, %rbp
    movl -84(%rbp), %eax
    cmpl $0, %eax
    je .Ladjust_with_exponent_0
    /*subtract Bias(127), Mantissa len(23) & Bits for bounds computation(2)*/
    subl $152, %eax
    movl %eax, -92(%rbp)
    movl -88(%rbp), %eax
    movl $1, %ebx
    sall $23, %ebx
    orl %ebx, %eax
    movl %eax, -96(%rbp)
    jmp .Ladjust_return
.Ladjust_with_exponent_0:
    /* exponent = 1 - Bias - mantissa len - bits for bounds computation */
    movl $-151, -92(%rbp)
    movl -88(%rbp), %eax
    movl %eax, -96(%rbp)
.Ladjust_return:
    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * Determine the interval of valid outputs, by computing
 * the halfway points to the next larger and smaller floating point number.
 *
 * Stack map:
 *  -84 => exponent
 *  -88 => mantissa
 *  -92 => adj. exponent
 *  -96 => adj. mantissa
 *  -100 => low output interval
 *  -104 => mid output interval
 *  -108 => high output interval
 */
compute_output_interval:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r8 /*mantissa*/

    movl -96(%rbp), %r8d
    movl %r8d, %eax
    imull $4, %eax
    movl %eax, -104(%rbp)
    movl %eax, %ebx
    addl $2, %ebx
    movl %ebx, -108(%rbp)
    subl $1, %eax
    movl -88(%rbp), %ebx
    cmpl $0, %ebx
    jne .Llow_shift_compute_interval
    movl -84(%rbp), %ecx
    cmpl $1, %ecx
    jle .Llow_shift_compute_interval
    jmp .Lcompute_interval_return
.Llow_shift_compute_interval:
    subl $1, %eax
.Lcompute_interval_return:
    movl %eax, -100(%rbp)

    popq %r8
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
    pushq %rbp
    pushq %r8
    pushq %r9
    pushq %r10
    movq %rsp, %rbp
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

    movq %rbp, %rsp
    popq %r10
    popq %r9
    popq %r8
    popq %rbp
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
 * Stack map:
 *  -92 => adj. exponent
 *  -96 => adj. mantissa
 *  -100 => low output interval
 *  -104 => mid output interval
 *  -108 => high output interval
 *  -112 => low interval conversion
 *  -116 => mid interval conversion
 *  -120 => high interval conversion
 */
convert_output_interval:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r8 /* Factor index */
    pushq %r9 /* Factor index case < 0 */
    pushq %r10 /* Shift value */
    pushq %r11 /* Factor */
    xorq %r8, %r8
    movl -92(%rbp), %eax
    cmpl $0, %eax
    jl .Lconvert_with_sub_zero_exponent
    /* adjusted exponent >= 0:
     * prepare factor array index & shift value */
    movl %eax, %edi
    callq log10pow2
    movl %eax, %r8d
    movl %r8d, %r10d
    movl -92(%rbp), %eax
    imull $-1, %eax
    addl %eax, %r10d
    addl $59, %r10d
    movl %r8d, %edi
    callq pow5bits
    addl %eax, %r10d
    subl $1, %r10d
    /* Get the factor from the factor array */
    leaq FLOAT_POW5_INV_SPLIT(%rip), %rax
    leaq 0x0(,%r8,8), %r8
    movq (%r8, %rax), %rax
    movq %rax, %r11
    jmp .Lperform_conversion
.Lconvert_with_sub_zero_exponent:
    /* adjusted exponent < 0:
     * prepare factor array index & shift value */
    imull $-1, %eax
    movl %eax, %edi
    callq log10pow5
    movl %eax, %r8d
    movl -92(%rbp), %eax
    imull $-1, %eax
    subl %r8d, %eax
    movl %eax, %r9d
    movl %r9d, %edi
    callq pow5bits
    subl $61, %eax
    movl %r8d, %r10d
    subl %eax, %r10d
    /* Get the factor from the factor array */
    leaq FLOAT_POW5_SPLIT(%rip), %rax
    leaq 0x0(,%r9,8), %r9
    movq (%r9, %rax), %rax
    movq %rax, %r11
.Lperform_conversion:
    /* lower bound of output interval */
    movl -100(%rbp), %edi
    movq %r11, %rsi
    movl %r10d, %edx
    callq scale_and_shift_output_interval
    movl %eax, -112(%rbp)
    /* mid of output interval */
    movl -104(%rbp), %edi
    movq %r11, %rsi
    movl %r10d, %edx
    callq scale_and_shift_output_interval
    movl %eax, -116(%rbp)
    /* upper bound of output interval */
    movl -108(%rbp), %edi
    movq %r11, %rsi
    movl %r10d, %edx
    callq scale_and_shift_output_interval
    movl %eax, -120(%rbp)

.Lconvert_result:
    popq %r11
    popq %r10
    popq %r9
    popq %r8
    movq %rbp, %rsp
    popq %rbp
    retq
