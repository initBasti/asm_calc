.include "src/check.S"

/* =====================================================
 * a ^ b
 * parameter:
 *  a (base) => rdi
 *  b (exponent) => rsi
 */
power:
    pushq %r8
    movzbl %dil, %eax
    movzbl %sil, %ebx
    movl $1, %r8d
.Lpower_loop:
    movl %ebx, %ecx
    andl $1, %ecx
    jz .Levennumber
    imull %eax, %r8d
.Levennumber:
    imull %eax, %eax
    shrl $1, %ebx
    cmpl $0, %ebx
    ja .Lpower_loop
    movl %r8d, %eax
    nop
    popq %r8
    retq

/* =============================================
 * Return the predefined value for the operator symbol
 * This is called after operator_check, where the length
 * of the string is tested.
 * parameter:
 *  rdi => string
 * return:
 *  '+' = 1 (Addition)
 *  '-' = 2 (Subtraction)
 *  'x' = 3 (Multiplication)
 *  '/' = 4 (Division)
 *  '^' = 5 (Exponantiation)
 *  'R' = 6 (nth root of)
 */
operator_value:
    pushq %rdi
    pushq %r8

    movzbl (%rdi), %eax
    cmpb $0x2B, %al
    jne .Lsubtract_value
    movl $1, %r8d
    jmp .Loperator_match
.Lsubtract_value:
    cmpb $0x2D, %al
    jne .Lmultiply_value
    movl $2, %r8d
    jmp .Loperator_match
.Lmultiply_value:
    cmpb $0x78, %al
    jne .Ldivsion_value
    movl $3, %r8d
    jmp .Loperator_match
.Ldivsion_value:
    cmpb $0x2F, %al
    jne .Lexponantiation_value
    movl $4, %r8d
    jmp .Loperator_match
.Lexponantiation_value:
    cmpb $0x5E, %al
    jne .Lroot_value
    movl $5, %r8d
    jmp .Loperator_match
.Lroot_value:
    cmpb $0x52, %al
    jne .Linvalid_value
    movl $6, %r8d
    jmp .Loperator_match
.Linvalid_value:
    movl $0, %eax
    popq %r8
    popq %rdi
    ret

.Loperator_match:
    movl %r8d, %eax
    popq %r8
    popq %rdi
    ret

/* =====================================================
 * Convert the integer part of the ASCII decimal representation
 * of a number to a floating point number.
 *
 * parameter:
 *  rdi => pointer to string
 *
 * return:
 *  xmm0 => result
 */
parse_integer_part:
    pushq %rbp
    pushq %r8
    movq %rsp, %rbp

    /* set result to 0 and place it on the stack */
    vxorps %xmm0, %xmm0, %xmm0
    vmovss %xmm0, -4(%rbp)

    movq %rdi, %r8
    jmp .Lparse_int_loop
.Lparse_int_calculate:
    subl $0x30, %eax
    /* result *= 10 */
    vmovss -4(%rbp), %xmm1
    vmovss .Lbinary_float_of_decimal_10(%rip), %xmm0
    vmulss %xmm0, %xmm1, %xmm1
    /* convert integer to float and add to result */
    vcvtsi2ss %eax, %xmm0, %xmm0
    vaddss %xmm0, %xmm1, %xmm0
    vmovss %xmm0, -4(%rbp)
.Lparse_int_loop:
    movzbl (%r8), %eax
    incq %r8
    cmpb $0x2E, %al
    je .Lparse_int_return
    cmpb $0, %al
    jne .Lparse_int_calculate
.Lparse_int_return:
    vmovss -4(%rbp), %xmm0
    movq %rbp, %rsp
    popq %r8
    popq %rbp
    retq

.Lbinary_float_of_decimal_10:
	.long	1092616192

/* =====================================================
 * Determine if the string contains a decimal point.
 *
 * parameter:
 *  rdi [string] => pointer to the first character of null terminated string
 *
 * return:
 *  Success:
 *  rax [Address] => Address of the first character after the decimal point
 *  or
 *  rax [Integer] => 0, when no decimal point was found
 *  Failure:
 *  rax [Integer] => -1, when more than 1 decimal point is present
 */
find_fractal_part:
    pushq %r8
    xorq %r8, %r8
.Lfind_fractal_loop:
    movzbl (%rdi), %eax
    incq %rdi
    cmpb $0x2E, %al
    je .Lfind_fractal_decimal_point
    cmpb $0x00, %al
    jne .Lfind_fractal_loop
    movq %r8, %rax
    jmp .Lfind_fractal_return
.Lfind_fractal_decimal_point:
    cmpq $0x00, %r8
    jne .Lfind_fractal_two_decimal_points
    movq %rdi, %r8
    jmp .Lfind_fractal_loop
.Lfind_fractal_two_decimal_points:
    movq $-0x01, %rax
.Lfind_fractal_return:
    popq %r8
    retq

/* =====================================================
 * Convert the fractal-part of ASCII decimal representation of a number
 * to a floating point number.
 * Multiplier = 0.1, Result = 0
 * Loop through the digits until the null terminator,
 * result = result + (digit * multiplier)
 * Multiplier = Multiplier * 0.1
 *
 * parameter:
 *  rdi [string] => pointer to the first character after the decimal point
 *
 * return:
 *  xmm0 [float] => floating point number
 */
parse_fractal_part:
    pushq %rbp
    movq %rsp, %rbp

    vxorps %xmm0, %xmm0, %xmm0
    vmovss %xmm0, -4(%rbp)
    vmovss .Lbinary_float_of_decimal_0.10(%rip), %xmm0
    vmovss %xmm0, -8(%rbp)

    jmp .Lparse_fractal_loop
.Lparse_fractal_calculate:
    subl $0x30, %eax
    vcvtsi2ss %eax, %xmm1, %xmm1
    vmovss -8(%rbp), %xmm0
    vmulss %xmm0, %xmm1, %xmm1

    vmovss -4(%rbp), %xmm0
    vaddss %xmm0, %xmm1, %xmm0
    vmovss %xmm0, -4(%rbp)
    vmovss -8(%rbp), %xmm1
    vmovss .Lbinary_float_of_decimal_0.10(%rip), %xmm0
    vmulss %xmm0, %xmm1, %xmm1
    vmovss %xmm1, -8(%rbp)
.Lparse_fractal_loop:
    movzbl (%rdi), %eax
    incq %rdi
    cmpb $0, %al
    jne .Lparse_fractal_calculate
    vmovss -4(%rbp), %xmm0
    movq %rbp, %rsp
    popq %rbp
    retq

.Lbinary_float_of_decimal_0.10:
	.long    1036831949

/* =====================================================
 * Remove unwanted characters and recognize the sign of the number.
 * Change the string in place and null terminate the end
 * of the string in case it got shorter.
 *
 * parameter:
 *  rdi [string] => pointer to first character of null terminated string
 *
 * return:
 *  rax [integer] => Negative(-1) [negative number] , Positive(1) [positive number]
 */
prepare_string:
    pushq %rdi
    pushq %r8 /* input string */
    pushq %r9 /* index nr 1 */
    pushq %r10 /* index nr 2 */
    pushq %r11 /* index for clean up loop */
    pushq %r12 /* positive/negative number */

    movq %rdi, %r8

    xorq %r9, %r9
    xorq %r10, %r10
    xorq %r11, %r11
    movq $0x01, %r12
    movzbl (%r8), %eax
    cmpb $0x2D, %al
    je .Lprepare_number_negative
    jmp .Lprepare_loop
.Lprepare_number_negative:
    movq $-0x01, %r12
    incq %r9
.Lprepare_loop:
    movzbl (%r8, %r9), %edi
    cmpb $0x00, %dil
    je .Lprepare_clean_up
    callq is_digit
    cmpq $0x01, %rax
    je .Lprepare_is_digit_or_decimal_point
    cmpb $0x2E, %dil
    jne .Lprepare_illegal_char
.Lprepare_is_digit_or_decimal_point:
    movzbl (%r8, %r9), %eax
    movb %al, (%r8, %r10)
    incq %r9
    incq %r10
    jmp .Lprepare_loop
.Lprepare_illegal_char:
    incq %r9
    jmp .Lprepare_loop
.Lprepare_clean_up:
    movq %r10, %r11
.Lprepare_clean_loop:
    cmpq %r9, %r11
    jge .Lprepare_return
    movq $0x00, (%r8, %r11)
    incq %r11
    jmp .Lprepare_clean_loop
.Lprepare_return:
    movq %r12, %rax

    popq %r12
    popq %r11
    popq %r10
    popq %r9
    popq %r8
    popq %rdi
    retq

/* =====================================================
 * Convert a ASCII decimal representation of a number (e.g 1.5)
 * to a IEEE-754 floating point binary 32 number.
 *
 * String has to start with a digit or a '-'.
 *
 * parameter:
 *  rdi [string] => pointer to first character of null terminated string
 *
 * return:
 *  xmm0 [float] => floating point number
 */
parse_float:
    pushq %rbp
    pushq %r8
    movq %rsp, %rbp
    xorq %r8, %r8 /* sign multiplier */
    callq prepare_string
    movq %rax, %r8

    callq parse_integer_part
    movaps %xmm0, %xmm2

    callq find_fractal_part
    cmpq $-0x01, %rax
    je .Lparse_float_invalid_number
    cmpq $0, %rax
    je .Lparse_float_return

    movq %rax, %rdi
    callq parse_fractal_part
    movaps %xmm2, %xmm1
    vaddss %xmm0, %xmm1, %xmm0
    vcvtsi2ss %r8d, %xmm1, %xmm1
    vmulss %xmm1, %xmm0, %xmm0
    jmp .Lparse_float_return
.Lparse_float_invalid_number:
    vcvtsi2ss %eax, %xmm0, %xmm0
.Lparse_float_return:
    movq %rbp, %rsp
    popq %r8
    popq %rbp
    retq

/* =====================================================
 * Parse a equation to an array of integers, where every odd
 * element is a operator (see check.S:operator_value).
 * Save the array on the stack with an offset of 64 byte.
 *
 * parameters:
 *  rdi = number of parameters (argc)
 *  rsi = pointer to the address of the first parameter
 *
 * return:
 *  Success (0) | Invalid number (1) | Invalid operator (2)
 */
parse_equation:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx /* register for preserving the pointer to the array of arguments */
    pushq %r12 /* number of arguments */
    pushq %r13 /* current index of the argument counter */
    pushq %r14 /* length of the array */
    pushq %r15

    xorq %r13, %r13
    xorq %r14, %r14

    movq %rdi, %r12
    movq %rsi, %rbx

    /* Create a offset of 64 bytes from the SP */
    subq $64, %rsp
    movq %r12, %rax
    imulq $8, %rax
    /* set the stack pointer to (SP - 64) - (argc * 8) */
    subq %rax, %rsp
    movq %rsp, _equation_array
.Leq_parse_loop:
    movq %r13, %rcx
    addq $1, %rcx
    imull $8, %ecx
    movq (%rbx, %rcx), %r15
    cmpq $0, %r15
    je .Leq_parse_next
    movq %r15, %rdi
    callq string_check
    cmpl $1, %eax
    jb .Leq_parse_operator
    ja .Leq_parse_next
.Leq_parse_number:
    movq %r15, %rdi
    callq parse_float
    movl $0, %eax
    vcvtsi2ss %eax, %xmm1, %xmm1
    comiss %xmm1, %xmm0
    je .Lerrornumber
    vmovss %xmm0, (%rsp, %r13, 8)
    incq %r14
    jmp .Leq_parse_next
.Leq_parse_operator:
    movq %r15, %rdi
    callq operator_value
    cmpl $0, %eax
    je .Lerroroperator
    movq %rax, (%rsp, %r13, 8)
    incq %r14
.Leq_parse_next:
    addq $1, %r13
    cmpq %r12, %r13
    jb .Leq_parse_loop
    movq $0, %rax
    jmp .Leq_parse_return
.Lerrornumber:
    movq $1, %rax
    jmp .Leq_parse_return
.Lerroroperator:
    movq $2, %rax
.Leq_parse_return:
    movl %r14d, _equation_array_length

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    retq
