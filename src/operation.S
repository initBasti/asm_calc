/* =====================================================
 * Choose the correct operation from the operator number
 *
 * parameter:
 *  rdi => first number
 *  rsi => operator (enum)
 *  rdx => second number
 *
 *      1 (Addition)
 *      2 (Subtraction)
 *      3 (Multiplication)
 *      4 (Division)
 *      5 (Exponentiation)
 *      6 (nth Root of)
 *
 * return:
 *  rax => result
 */
operation:
    xorl %eax, %eax
    cmpl $1, %esi
    je .Laddition
    cmpl $2, %esi
    je .Lsubstraction
    cmpl $3, %esi
    je .Lmultiplication
    cmpl $4, %esi
    je .Ldivision
.Laddition:
    addl %edi, %eax
    addl %edx, %eax
    jmp .Loperation_exit
.Lsubstraction:
    addl %edi, %eax
    subl %edx, %eax
    jmp .Loperation_exit
.Lmultiplication:
    imull %edi, %edx
    movq %rdx, %rax
    jmp .Loperation_exit
.Ldivision:
    callq division
.Loperation_exit:
    nop
    retq

/* =====================================
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
    popq %r8
    movl %edi, %eax
    movq %rdx, %r8
.Ldivision_loop:
    cqto
    idivl %r8d
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
    movq %r14, %rax
    popq %r8
    retq
