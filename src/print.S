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
