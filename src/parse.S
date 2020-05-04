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
.L1:
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
    ja .L1

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
 *  a (base) = rdi
 *  b (exponent) = rsi
 */
power:
    pushq %r8
    movzbl %dil, %eax
    movzbl %sil, %ebx
    movl $1, %r8d
.L10:
    movl %ebx, %ecx
    andl $1, %ecx
    jz .L11
    imull %eax, %r8d
.L11:
    imull %eax, %eax
    shrl $1, %ebx
    cmpl $0, %ebx
    ja .L10
    movl %r8d, %eax
    nop
    popq %r8
    retq

/* =====================================================
 * Get the length of a string
 * parameter:
 *  string (pointer to first char) = rdi
 */
getlen:
    pushq %r8
    xorl %r8d, %r8d
.L20:
    movzbl (%rdi), %eax
    testb %al, %al
    je .L21
    incl %r8d
    incq %rdi
    jmp .L20
.L21:
    movl %r8d, %eax
    nop
    popq %r8
    retq

