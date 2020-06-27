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
    /* 1. sign bit */
    sarl $31, %eax
    movzbl %al, %eax
    movl %eax, -52(%rbp)
    /* 2. exponent */
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    /* mantissa bits = 23*/
    sarl $23, %eax
    /* (1 << exponent bits(8)) - 1 = 255*/
    andl $255, %eax
    movl %eax, -56(%rbp)
    /* 3. mantissa */
    leaq -8(%rbp), %rax
    movl (%rax), %eax
    movl .LMantissa_mask, %ebx
    andl %ebx, %eax
    movl %eax, -60(%rbp)
    leaq -60(%rbp), %rax
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
 *  rdi => Stack pointer to the three parts
 *
 * return:
 *  rax => 1 (True is zero) | 0 (False is not zero)
 */
zero_check:
    movl (%rdi), %eax
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
 * Determine the interval of valid outputs, by computing
 * the halway points to the next larger and smaller floating point number.
 *
 * parameter:
 *  rdi => Stack pointer to the three parts
 *  addr+0 = mantissa, addr+4 = exponent, addr+8 = sign
 *
 * return:
 *  rax => Stack pointer to the interval parts (high/mid/low)
 *  (addr: rsp - 76 to rsp - 64)
 *  addr+0 = high, addr+4 = mid, addr+8 = low
 */
compute_output_interval:
    pushq %rbp
    pushq %r8 /*mantissa*/
    movq %rsp, %rbp

    movl (%rdi), %r8d
    movl %r8d, %eax
    imull $4, %eax
    movl %eax, -68(%rbp)
    movl %eax, %ebx
    addl $2, %ebx
    movl %ebx, -72(%rbp)
    subl $1, %eax
    /* mantissa |= 1 >> mantissa len(23) to get the original mantissa */
    movl %r8d, %ebx
    movl $1, %ecx
    sall $23, %ecx
    notl %ecx
    andl %ecx, %ebx
    cmpl $0, %ebx
    jne .Llow_shift_compute_interval
    movl 4(%rdi), %ecx
    cmpl $1, %ecx
    jle .Llow_shift_compute_interval
    jmp .Lcompute_interval_return
.Llow_shift_compute_interval:
    subl $1, %eax
.Lcompute_interval_return:
    movl %eax, -64(%rbp)
    leaq -72(%rbp), %rax

    movq %rbp, %rsp
    popq %r8
    popq %rbp

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
