/* =====================================================
 * Calculate the result of an equation saved within a contigious array.
 *
 *  for i = 3 ; i != 0 ; i--
 *      while (index = find_operator_with_precedence(i)) != 0
 *          array[index-1] = operation(array[index-1], array[index], array[index+1])
 *          move_up_index = index + 2
 *          while move_up_index < len(array)
 *              array[index] = array[move_up_index]
 *              index+=1, move_up_index+=1
 *          len(array) -= 2
 *
 *  register 10 & 11 are used across all sub functions of calculate_equation
 *  for the pointer to array[0] (r10) & the length of array(r11).
 *
 * return:
 *  rax => Result [Integer]
 */
calculate_equation:
    movq _equation_array, %r10
    movq $3, %r8
.Leq_calc_find_operator:
    movq %r8, %rdi
    callq find_operator_with_precedence
    testl %eax, %eax
    je .Leq_calc_next_precedence
    movq %rax, %r9

    vmovss -8(%r10, %r9, 8), %xmm0
    movq (%r10, %r9, 8), %rsi
    vmovss 8(%r10, %r9, 8), %xmm1
    callq operation
    vmovss %xmm0, -8(%r10, %r9, 8)

    movq %r9, %rdi
    movq %r9, %rsi
    addq $2, %rsi
    cmpq %r11, %rsi /* r11 is set in find_operator_with_precedence */
    jge .Leq_calc_cut_end
    callq move_up_array
    jmp .Leq_calc_find_operator
.Leq_calc_cut_end:
    subq $2, %r11
    movq %r11, _equation_array_length
    jmp .Leq_calc_find_operator
.Leq_calc_next_precedence:
    subq $1, %r8
    cmpq $0, %r8
    je .Leq_calc_return
    ja .Leq_calc_find_operator
.Leq_calc_return:
    movq (%r10), %rax
    retq

/* =====================================================
 * Traverse through the odd indeces of the array
 * (check_equation guaranteed that every odd index is a operator)
 * Check if the operator has priority level 1,2 or 3.
 * Level 1: '+', '-'
 * Level 2: 'x', '/'
 * Level 3: '^', 'R'
 *
 * parameter:
 *  rdi => current priority level
 *
 * return:
 *  rax => index of the operator or 0 @ no match
 */
find_operator_with_precedence:
    pushq %r8
    movq $1, %r8
    movq %rdi, %r9
    movq _equation_array_length, %r11
    cmpq $1, %r11
    je .Lfind_op_no_match
.Lfind_op_loop:
    movq (%r10, %r8, 8), %rdi
    callq precedence_level
    cmpq %rax, %r9
    je .Lfind_op_match
    addq $2, %r8
    cmpq %r11, %r8
    jl .Lfind_op_loop
.Lfind_op_no_match:
    movq $0, %rax
    jmp .Lfind_op_return
.Lfind_op_match:
    movq %r8, %rax
.Lfind_op_return:
    popq %r8
    retq

/* =====================================================
 * Match the operator number to a precedence level.
 * (operator >= 1 && operator <= 6, checked by parse_equation)
 *
 * parameter:
 *  rdi => operator [Integer]
 *
 * return:
 *  rax => precedence level [Integer]
 */
precedence_level:
    cmpq $3, %rdi
    jb .Lfirst_prec_level
    cmpq $4, %rdi
    ja .Lthird_prec_level
    movq $2, %rax
    jmp .Lprec_level_return
.Lfirst_prec_level:
    movq $1, %rax
    jmp .Lprec_level_return
.Lthird_prec_level:
    movq $3, %rax
.Lprec_level_return:
    retq

/* =====================================================
 * Shift the elements of an array to the left.
 * After the operation reduce the length variable of the array by 2.
 *
 * parameter:
 *  rdi => new index
 *  rsi => old index
 */
move_up_array:
.Lmov_up_arr_loop:
    movq (%r10, %rsi, 8), %r9
    movq %r9,(%r10, %rdi, 8)
    incq %rsi
    incq %rdi
    cmpq %r11, %rsi
    jb .Lmov_up_arr_loop
    subq $2, %r11
    movq %r11, _equation_array_length
    retq

/* =====================================================
 * Choose the correct operation from the operator number
 *
 * parameter:
 *  xmm0 => first number
 *  rsi => operator (enum)
 *  xmm1 => second number
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
    vaddss %xmm1, %xmm0, %xmm0
    jmp .Loperation_exit
.Lsubstraction:
    vsubss %xmm1, %xmm0, %xmm0
    jmp .Loperation_exit
.Lmultiplication:
    vmulss %xmm1, %xmm0, %xmm0
    jmp .Loperation_exit
.Ldivision:
    vdivss %xmm1, %xmm0, %xmm0
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
