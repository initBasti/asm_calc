.globl main
.data
.text

.include "src/print.S"
.include "src/check.S"


main:
    pushq %rbp 

    movl $1, %eax
    cmpl $4, %edi
    je .L1
    movl $1, %eax
    ret

.L1:
    pushq %rbx

    subq $8, %rsp 

    movq %rsi, %rbx
    movq 8(%rsi), %rbp
    movq %rbp, %rdi
    callq stringcheck
    testl %eax, %eax
    jne .L2
    movq 8(%rbx), %rbp
    movq %rbp, %rdi
    callq print
.L2:
    movq 16(%rbx), %rbp
    movsbl 0(%rbp), %edi
    callq opcheck 
    testl %eax, %eax 
    jne .L3
    movq 16(%rbx), %rbp
    movq %rbp, %rdi
    callq print
.L3:
    movq 24(%rbx), %rbp
    movq %rbp, %rdi
    callq stringcheck
    testl %eax, %eax 
    jne .L4
    movq 24(%rbx), %rbp
    movq %rbp, %rdi
    callq print
.L4:
    movl $0x0A, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq print
    movl $0, %eax
    addq $8, %rsp
    popq %rbx
    popq %rbp
    retq
