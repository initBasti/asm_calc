.globl main
.section .rodata
invalidoperator:
    .string "Invalid operator\n"
invalidnumber:
    .string "Invalid number\n"
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
    xorq %r12, %r12
    xorq %r13, %r13
    xorq %r14, %r14
    xorq %r15, %r15

    subq $8, %rsp

    movq %rsi, %rbx
    movq 8(%rsi), %rbp
    movq %rbp, %rdi
    callq stringcheck
    testl %eax, %eax
    jne .Lerrornumber
    callq parseint
    movl %eax, %r12d
.Lsecond_num:
    movq 24(%rbx), %rbp
    movq %rbp, %rdi
    callq stringcheck
    testl %eax, %eax
    jne .Lerrornumber
    callq parseint
    movl %eax, %r13d
.Loperator:
    movq 16(%rbx), %rbp
    movsbl 0(%rbp), %edi
    callq opcheck
    cmpl $0, %eax
    je .Lerroroperator
    movq %r12, %rdi
    movq %r13, %rsi
    movl %eax, %edx
    callq operation
.Lprintoperation:
    movq 8(%rbx), %rdi
    callq printstr
    movq 16(%rbx), %rdi
    callq printstr
    movq 24(%rbx), %rdi
    callq printstr
    /* print '=' */
    movl $0x3D, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq printstr
.Lresult:
    movq %r14, %rdi
    callq printint
    cmpq $0, %r15
    je .Laddnewline
    /* print ',' */
    movl $0x2E, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq printstr
    movq %r15, %rdi
    callq printint
    jmp .Laddnewline
.Laddnewline:
    movl $0x0A, -4(%rbp)
    leaq -4(%rbp), %rdi
    callq printstr
.Lexit:
    addq $8, %rsp
    popq %rbx
    popq %rbp
    movl $0x3C, %eax
    movl $0x00, %edi
    syscall
    retq

.Lerrornumber:
    movq $invalidnumber, %rdi
    callq printstr
    jmp .Lexit
.Lerroroperator:
    movq $invalidoperator, %rdi
    callq printstr
    jmp .Lexit
