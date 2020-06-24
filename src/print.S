.include "src/parse.S"

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
 * parameter:
 *  xmm0 => input floating-point number
 *
 * return:
 *  rax => Stack pointer to the three parts (size 4 bytes each)
 */
split_into_parts:
    pushq %rbp
    movq %rsp, %rbp
    vmovss %xmm0, -8(%rbp)
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    sall $31, %eax
    movl %eax, -52(%rbp)
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    movl .LExponent_mask, %ebx
    andl %ebx, %eax
    movl %eax, -56(%rbp)
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    movl .LMantissa_mask, %ebx
    andl %ebx, %eax
    movl %eax, -60(%rbp)
    leaq -60(%rbp), %rax
    movq %rbp, %rsp
    popq %rbp
    retq
.LExponent_mask:
    .long 2139095040
.LMantissa_mask:
    .long 8388607

/* ======================================================
 * Check if the number is equal to zero.
 *
 * parameter:
 *  rdi => Stack pointer to the three parts
 *
 * return:
 *  rax => 1 (True is zero) | 0 (False is not zero)
 */
zero_check:
    movq (%rdi), %rax
    cmpq $0, %rax
    jne .Lisnotzero
    movq 4(%rdi), %rax
    cmpq $0, %rax
    jne .Lisnotzero
    movq $1, %rax
    jmp .Lzero_check_return
.Lisnotzero:
    movq $0, %rax
.Lzero_check_return:
    retq

/* ======================================================
 * Adjust sub parts of the floating point number to prepare
 * the number for the conversion to an unsigned integer.
 * That involves moving the decimal 'dot' to the rightmost
 * position.
 *
 * parameter:
 *  rdi => Stack pointer to the three parts
 *  addr+0 = mantissa, addr+4 = exponent, addr+8 = sign
 *
 * return:
 *  rax => Stack pointer to the three parts (size 4 bytes each)
 */
adjust_parts:
    movl 4(%rdi), %eax
    cmpl $0, %eax
    je .Ladjust_with_exponent_0
    /*subtract Bias(127), Mantissa len(23) & Bits for bounds computation(2)*/
    subl $152, %eax
    movl %eax, 4(%rdi)
    movl (%rdi), %eax
    movl $1, %ebx
    sall $23, %ebx
    orl %ebx, %eax
    movl %eax, (%rdi)
    jmp .Ladjust_return
.Ladjust_with_exponent_0:
    /* exponent = 1 - Bias - mantissa len - bits for bounds computation */
    movl $-151, 4(%rdi)
.Ladjust_return:
    movq %rdi, %rax
    retq

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
 * print a '=' using the write syscall
 */
print_equal_sign:
    pushq %r8
    movl $0x3D, %r8d
    leaq (%r8), %rdi
    callq print_char
    popq %r8
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
