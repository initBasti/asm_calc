/* -----------------------------------------------------
 * Choose the correct operation from the operator (cli arg 2)
 * Parameter:
 *  rdi => First integer
 *  rsi => second integer
 *  rdx => operator (enum)
 *
 *      1 (Addition)
 *      2 (Subtraction)
 */
operation:
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
    addl %edi, %eax
    addl %esi, %eax
    jmp .Loperation_exit
.Lsubstraction:
    addl %edi, %eax
    subl %esi, %eax
    jmp .Loperation_exit
.Lmultiplication:
    imull %edi, %esi
    movq %rsi, %rax
    jmp .Loperation_exit
.Ldivision:
    movl %edi, %eax
    cqto
    idivl %esi
    movl %edx, %r15d
.Loperation_exit:
    nop
    retq
