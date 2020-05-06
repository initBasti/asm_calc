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
.Laddition:
    addl %edi, %eax
    addl %esi, %eax
    jmp .Loperation_exit
.Lsubstraction:
    addl %edi, %eax
    subl %esi, %eax
    jmp .Loperation_exit
.Loperation_exit:
    nop
    retq
