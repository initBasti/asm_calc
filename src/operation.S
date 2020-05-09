/* -----------------------------------------------------
 * Choose the correct operation from the operator (cli arg 2)
 * Parameter:
 *  rdi => First integer
 *  rsi => second integer
 *  rdx => operator (enum)
 *
 *      1 (Addition)
 *      2 (Subtraction)
 *      3 (Multiplication)
 *      4 (Division)
 *
 */
operation:
    pushq %r13
    xorq %r13, %r13

    xorl %eax, %eax
    cmpl $1, %edx
    je .Laddition
    cmpl $2, %edx
    je .Lsubstraction
    cmpl $3, %edx
    je .Lmultiplication
    cmpl $4, %edx
    je .Ldivision
.Laddition:
    addl %edi, %r14d
    addl %esi, %r14d
    jmp .Loperation_exit
.Lsubstraction:
    addl %edi, %r14d
    subl %esi, %r14d
    jmp .Loperation_exit
.Lmultiplication:
    imull %edi, %esi
    movq %rsi, %r14
    jmp .Loperation_exit
.Ldivision:
    callq division
.Loperation_exit:
    nop
    popq %r13
    retq

/*
 *  Algorithm Division:
 *      a / b = c R: d
 *      if first division
 *      result 1(before floating point) = c
 *      else
 *      result 2(after floating point) = (result2 * 10) + c
 *      d = d * 10 if d > 0
 *      a = d
 *
 *  Note: Easy solution which fails on more than 9 positions after the floating point
 *        because of 32-bit limitations in the current code (2020-05-09)
 */
division:
    movl %edi, %eax
.Ldivision_loop:
    cqto
    idivl %esi
    cmpq $0, %r13
    jne .Ldivision_after_floating_point
    movl %eax, %r14d
    jmp .Ldivision_remainder_check
.Ldivision_after_floating_point:
    imull $10, %r15d
    addl %eax, %r15d
.Ldivision_remainder_check:
    cmpl $0, %edx
    je .Loperation_exit
    incq %r13
    imull $10, %edx
    movl %edx, %eax
    cmpq $9, %r13
    jl .Ldivision_loop
    retq
