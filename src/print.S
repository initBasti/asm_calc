.include "src/parse.S"

/* ======================================================
 * print a string until the null terminator
 * parameter:
 *  rdi => pointer to the first character
 */
printstr:
    pushq %rbp
    movq %rdi, %rbp
.loop:
    movzbl (%rbp), %eax
    testb %al, %al
    je .print_success
    movq %rbp, %rdi
    callq printchar
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
 */
printint:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r8
    pushq %r9
    pushq %r10
    xorq %r8, %r8
    xorq %r9, %r9
    xorq %r10, %r10

    callq getnumofdigits
    movl %eax, %r8d
    movq %rdi, %r9
.Lprintint_loop:
    decq %r8
    movq $10, %rdi
    movq %r8, %rsi
    callq power
    movl %eax, %ebx
    movzbl %r9b, %eax
    cqto
    idivl %ebx
    movl %eax, %r10d
    addl $0x30, %eax
    movl %eax, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq printchar
    /* Subtract the digit[r10] * 10^(r8)[ebx] from the number[r9] */
    imul %ebx, %r10d
    subq %r10, %r9

    cmpq $0, %r8
    ja .Lprintint_loop

    nop
    popq %r10
    popq %r9
    popq %r8
    movq %rbp, %rsp
    popq %rbp
    retq

/* ======================================================
 * print a single character using the write syscall
 * parameter:
 *  rdi => pointer to character
 */
printchar:
    movq %rdi, %rsi /* msg argument of write syscall */
    movq $0x01, %rax /* write syscall */
    movq $0x01, %rdi /* write to stdout */
    movq $0x01, %rdx /* length to write (1) */
    syscall
    retq
