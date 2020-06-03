.include "src/option.S"

/* =============================================
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
    pushq %rdi
    pushq %rsi
    xorq %r8, %r8 /* total amount of arguments */
    movq $1, %r9 /* current index of the argument counter */
    xorq %r10, %r10 /* current offset (index * 8) */
    xorq %r11, %r11 /* last element boolean (1 = number & 0 = operator) */

    movq %rdi, %r8
    movq %rsi, %rbx

.Leq_check_loop:
    movq %r9, %r10
    imull $8, %r10d
    movq (%rbx, %r10), %rdi
    cmpq $0, %rdi
    je .Leq_check_next
    callq string_check
    cmpl $1, %eax
    jbe .Lequation_element
    cmpl $2, %eax
    je .Leq_check_option
    ja .Lerror_argument
.Leq_check_option:
    callq activate_option
    jmp .Leq_check_next
.Lequation_element:
    cmpl %eax, %r11d
    je .Lerror_invalid_sequence
    movl %eax, %r11d
.Leq_check_next:
    addq $1, %r9
    cmpq %r8, %r9
    jb .Leq_check_loop
    movq $0, %rax
    jmp .Leq_check_return
.Lerror_argument:
    movq $1, %rax
    jmp .Leq_check_return
.Lerror_invalid_sequence:
    movq $2, %rax
.Leq_check_return:
    popq %rsi
    popq %rdi
    retq

/* =============================================
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
    pushq %rdi
    callq operator_check
    testb %al, %al
    je .Lstring_check_number
    movl $0, %eax
    jmp .Lstring_check_return
.Lstring_check_number:
    callq number_check
    testb %al, %al
    je .Lstring_check_option
    movl $1, %eax
    jmp .Lstring_check_return
.Lstring_check_option:
    callq option_check
    testb %al, %al
    je .Lstring_check_failure
    movl $2, %eax
    jmp .Lstring_check_return
.Lstring_check_failure:
    movl $3, %eax
.Lstring_check_return:
    popq %rdi
    retq

/* =============================================
 * Determine if every character of the string is a digit
 * parameter:
 *  rdi => string
 * return:
 *  True(1) | False(0)
 */
number_check:
    pushq %rdi
    popq %r8
    movq %rdi, %r8
.Lnumber_next:
    movzbl (%r8), %eax
    testb %al, %al
    je .Lnumber_success
    incq %r8

    movq %rax, %rdi
    callq is_digit
    cmpq $0, %rax
    jne .Lnumber_next
    je .Lnumber_fail
.Lnumber_success:
    movl $0x01, %eax
    popq %rdi
    retq
.Lnumber_fail:
    movl $0x00, %eax
    popq %rdi
    retq

/* =============================================
 * Compare the string with the following predefined values:
 *  '+' - Addition
 *  '-' - Subtraction
 *  'x' - Multiplication
 *  '/' - Division
 *  '^' - Exponentiation
 *  'R' - nth root of
 * parameter:
 *  rdi => string
 * return:
 *  True(1) | False(0)
 */
operator_check:
    pushq %rdi
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
    popq %rdi
    movl $0, %eax
    retq
.Loperator_next_char:
    incq %rdi
    movzbl (%rdi), %eax
    testb %al, %al
    jne .Loperator_failure
.Loperator_success:
    popq %rdi
    movl $1, %eax
    retq

/* =============================================
 * Test the string for a sequence of '--', followed by
 * anything but a null terminator
 * parameter:
 *  rdi => string
 * return:
 *  True(1) | False(0)
 */
option_check:
    pushq %rdi
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
    popq %rdi
    movl $0, %eax
    retq
.Loption_success:
    popq %rdi
    movl $1, %eax
    retq

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
    subq $0x30, %rdi
    cmpq $0x09, %rdi
    ja .Lis_digit_False
    cmpq $0x00, %rdi
    jb .Lis_digit_False
    movq $0x01, %rax
    retq
.Lis_digit_False:
    movq $0x00, %rax
    retq

