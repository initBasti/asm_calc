.include "src/option.S"

/* =====================================================
 * Check if a character represents a digit from 0-9.
 *
 * parameter:
 *  rdi [character] => character value as part of a string
 *
 * return:
 *  rax [Boolean] => True(1) or False(0)
 */
is_digit:
    cmpq $0x39, %rdi
    ja .Lis_digit_False
    cmpq $0x30, %rdi
    jb .Lis_digit_False
    movq $0x01, %rax
    retq
.Lis_digit_False:
    movq $0x00, %rax
    retq

/* ======================================================
 * Get the length of a string.
 *
 * parameter:
 *  rdi [string] => pointer to string
 *
 * return:
 *  eax [Integer] => length of the input string
 */
strlen:
    xorq %r8, %r8
.Lstrlen_loop:
    movzbl (%rdi), %eax
    testb %al, %al
    cmpb $0, %al
    je .Lstrlen_return
    incl %r8d
    incq %rdi
    jmp .Lstrlen_loop
.Lstrlen_return:
    movl %r8d, %eax
    retq

/* ======================================================
 * Determine if every character of the string is a digit
 * Only allowed special cases are a single decimal point
 * or a hyphon to signal a negativ number.
 * The decimal point cannot be the first or last character.
 * The hyphon is only valid at the first position.
 *
 * parameter:
 *  rdi => string
 *
 * return:
 *  True(1) | False(0)
 */
number_check:
    pushq %r12 /* register for the string */
    pushq %r13 /* string length */
    pushq %r14 /* loop counter */
    pushq %r15/* found decimal point */

    xorq %r13, %r13
    xorq %r14, %r14
    movq %rdi, %r12
    callq strlen
    movl %eax, %r13d
.Lnumber_check_loop:
    movzbl (%r12), %eax
    testb %al, %al
    je .Lnumber_success
    incq %r12
    cmpl $0x00, %r14d
    jne .Lnumber_digit_check
    cmpb $0x2D, %al
    je .Lnumber_check_loop

.Lnumber_digit_check:
    movq %rax, %rdi
    callq is_digit
    cmpq $0, %rax
    jne .Lnumber_increase_counter
    je .Lnumber_check_for_decimal_point
.Lnumber_increase_counter:
    incl %r14d
    jmp .Lnumber_check_return

.Lnumber_check_for_decimal_point:
    cmpl $0x00, %r14d
    /* It is neither a digit nor a '-', so even if it is
       decimal point, it is not at a valid location */
    je .Lnumber_fail
    movl %r13d, %ecx
    subl $1, %ecx
    cmpl %ecx, %r14d
    /* The decimal point cannot be the last character */
    je .Lnumber_fail
    cmpl $0, %r15d
    /* The number cannot contain more than one decimal point */
    jne .Lnumber_fail
    cmpb $0x2E, %al
    jne .Lnumber_fail
    incl %r15d
    jmp .Lnumber_increase_counter

.Lnumber_success:
    movl $0x01, %eax
    jmp .Lnumber_check_return
.Lnumber_fail:
    movl $0x00, %eax
.Lnumber_check_return:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    retq

/* ======================================================
 * Compare the string with the following predefined values:
 *  '+' - Addition
 *  '-' - Subtraction
 *  'x' - Multiplication
 *  '/' - Division
 *  '^' - Exponentiation
 *  'R' - nth root of
 * If the next character is not a null terminator
 * it cannot be a operator
 *
 * parameter:
 *  rdi => string
 *
 * return:
 *  True(1) | False(0)
 */
operator_check:
    movzbl (%rdi), %eax
    cmpb $0x2B, %al
    jb .Loperator_failure
    je .Loperator_next_char
    cmpb $0x2D, %al
    je .Loperator_next_char
    cmpb $0x2F, %al
    je .Loperator_next_char
    cmpb $0x52, %al
    je .Loperator_next_char
    cmpb $0x5E, %al
    je .Loperator_next_char
    cmpb $0x78, %al
    je .Loperator_next_char
.Loperator_failure:
    movl $0, %eax
    retq
.Loperator_next_char:
    incq %rdi
    movzbl (%rdi), %eax
    testb %al, %al
    jne .Loperator_failure
.Loperator_success:
    movl $1, %eax
    retq

/* ======================================================
 * Test the string for a sequence of '--', followed by
 * anything but a null terminator
 * parameter:
 *  rdi => string
 * return:
 *  True(1) | False(0)
 */
option_check:
    movzbl (%rdi), %eax
    cmpb $0x2D, %al
    jne .Loption_failure
    incq %rdi
    movzbl (%rdi), %eax
    cmpb $0x2D, %al
    jne .Loption_failure
    incq %rdi
    movzbl (%rdi), %eax
    testb %al, %al
    jne .Loption_success
.Loption_failure:
    movl $0, %eax
    retq
.Loption_success:
    movl $1, %eax
    retq

/* ======================================================
 * Test if the string matches one of the valid parameter types:
 *  - number
 *  - operator
 *  - command line option
 * parameter:
 *  rdi => string
 * return:
 *  operator    = 0
 *  number      = 1
 *  option      = 2
 *  invalid     = 3
 */
string_check:
    pushq %r12
    movq %rdi, %r12
    callq operator_check
    testb %al, %al
    je .Lstring_check_number
    movl $0, %eax
    jmp .Lstring_check_return
.Lstring_check_number:
    movq %r12, %rdi
    callq number_check
    testb %al, %al
    je .Lstring_check_option
    movl $1, %eax
    jmp .Lstring_check_return
.Lstring_check_option:
    movq %r12, %rdi
    callq option_check
    testb %al, %al
    je .Lstring_check_failure
    movl $2, %eax
    jmp .Lstring_check_return
.Lstring_check_failure:
    movl $3, %eax
.Lstring_check_return:
    popq %r12
    retq

/* ======================================================
 * Check if the equation is valid.
 * It is not valid, if it contains a sequence of
 * two elements of the same type.
 * (eg. number, number / operator, operator)
 *
 * parameter:
 *  rdi = number of parameters (argc)
 *  rsi = pointer to the address of the first parameter
 *
 * result:
 *  Valid equation (0), Wrong argument (1), Invalid sequence (2)
 *  _option_bits = options
 */
check_equation:
    pushq %rbx /* register for preserving the pointer to the array of arguments */
    pushq %r12 /* total amount of arguments */
    pushq %r13 /* current index of the argument counter */
    pushq %r14 /* last element boolean (1 = number & 0 = operator) */
    pushq %r15 /* register for preserving the string argument */
    movq $1, %r13
    xorq %r14, %r14

    movq %rdi, %r12
    movq %rsi, %rbx

.Leq_check_loop:
    movl %r13d, %eax
    imull $8, %eax
    movq (%rbx, %rax), %r15
    cmpq $0, %r15
    je .Leq_check_next
    movq %r15, %rdi
    callq string_check
    cmpl $1, %eax
    jbe .Lequation_element
    cmpl $2, %eax
    je .Leq_check_option
    ja .Lerror_argument
.Leq_check_option:
    movq %r15, %rdi
    callq activate_option
    jmp .Leq_check_next
.Lequation_element:
    cmpl %eax, %r14d
    je .Lerror_invalid_sequence
    movl %eax, %r14d
.Leq_check_next:
    addq $1, %r13
    cmpq %r12, %r13
    jb .Leq_check_loop
    movq $0, %rax
    jmp .Leq_check_return
.Lerror_argument:
    movq $1, %rax
    jmp .Leq_check_return
.Lerror_invalid_sequence:
    movq $2, %rax
.Leq_check_return:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    retq

