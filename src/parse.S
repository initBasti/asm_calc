parseint:
    pushq %rbp
    pushq %rbx
    pushq %rdi
    pushq %r10

    xorq %r10, %r10

    /* rdi contains the pointer to the string */
    movq %rdi, %r8
    callq getlen
    movl %eax, %r9d
.Lparseint_loop:
    subq $1, %r9

    /* get the correct power of 10 for the digit
     * rdi is the current length */
    movq $10, %rdi
    movzbl %r9b, %esi
    callq power
    movl %eax, %ebx

    movzbl (%r8), %eax
    subl $0x30, %eax
    /* multiply the digit with its power of 10 */
    imull %ebx, %eax
    addl %eax, %r10d

    incq %r8
    cmpq $0, %r9
    ja .Lparseint_loop

    /* add result to eax */
    movl %r10d, %eax
    nop
    popq %r10
    popq %rdi
    popq %rbx
    popq %rbp
    retq

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

/* =====================================================
 * Get the length of a string
 * parameter:
 *  string (pointer to first char) => rdi
 */
getlen:
    pushq %r8
    xorl %r8d, %r8d
.Lgetlen_loop:
    movzbl (%rdi), %eax
    testb %al, %al
    je .Lfound_nullterminator
    incl %r8d
    incq %rdi
    jmp .Lgetlen_loop
.Lfound_nullterminator:
    movl %r8d, %eax
    nop
    popq %r8
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
 getnumofdigits:
    pushq %rbx

    /* idivl requires edx:eax as the dividend, zero edx and sign extend the number */
    movzbl %dil, %eax
    movl $10, %ebx
.Lgetnumofdigits_loop:
    cqto
    idivl %ebx
    incq %r8
    cmpl $0, %eax
    ja .Lgetnumofdigits_loop
    movl %r8d, %eax
    nop
    popq %rbx
    retq
