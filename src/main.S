.globl main
.data
.text

.include "src/print.S"
.include "src/check.S"
.include "src/operation.S"


main:
    pushq %rbp

    movl $1, %eax
    cmpl $4, %edi
    je .Lfirst_num
    movl $1, %eax
    ret

.Lfirst_num:
    pushq %rbx
    xorq %r13, %r13
    xorq %r14, %r14
    xorq %r15, %r15

    subq $8, %rsp

    movq %rsi, %rbx
    movq 8(%rsi), %rbp
    movq %rbp, %rdi
    callq stringcheck
    testl %eax, %eax
    jne .Lsecond_num
    callq parseint
    movl %eax, %r13d
.Lsecond_num:
    movq 24(%rbx), %rbp
    movq %rbp, %rdi
    callq stringcheck
    testl %eax, %eax
    jne .Loperator
    callq parseint
    movl %eax, %r14d
.Loperator:
    movq 16(%rbx), %rbp
    movsbl 0(%rbp), %edi
    callq opcheck
    cmpl $0, %eax
    je .Lexit
    movq %r13, %rdi
    movq %r14, %rsi
    movl %eax, %edx
    callq operation
    movl %eax, %r15d
.Lprintoperation:
    movq 8(%rbx), %rdi
    callq printstr
    movq 16(%rbx), %rdi
    callq printstr
    movq 24(%rbx), %rdi
    callq printstr
    movl $0x3D, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq printstr
.Lresult:
    movq %r15, %rdi
    callq printint
    jmp .Lexit
.Lexit:
    movl $0x0A, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq printstr
    movl $0, %eax
    addq $8, %rsp
    popq %rbx
    popq %rbp
    retq
