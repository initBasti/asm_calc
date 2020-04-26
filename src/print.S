print:
    pushq %rbp
    movq %rdi, %rbp
.loop:
    movzbl (%rbp), %eax
    testb %al, %al
    je .print_success
    movq $0x01, %rax /* write syscall */
    movq $0x01, %rdi /* write to stdout */
    movq %rbp, %rsi /* msg argument of write syscall */
    movq $0x01, %rdx /* length to write (1) */
    syscall
    addq $0x01, %rbp
    jmp .loop

.print_success:
    movl $0, %eax
    nop
    popq %rbp
    retq

