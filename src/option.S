/* ===========================================
 * Set the apropriate bit in the option register
 * parameter:
 *  rdi => string from CLI argument
 * return:
 *  eax => 0 (valid option & bit is set)
 *  eax => 1 (invalid option)
 */
activate_option:
    pushq %r8
    pushq %r9
    pushq %r10
    pushq %r11
    callq validate_option
    cmpl $0x01, %eax
    je .Lactivate_help
    jne .Linvalid_option
.Lactivate_help:
    movq $0x01, _option_bits
    movl $0x00, %eax
    jmp .Lactivate_return
.Linvalid_option:
    movl $0x01, %eax
.Lactivate_return:
    popq %r11
    popq %r10
    popq %r9
    popq %r8
    retq

/* ===========================================
 * compare the parameter with a pre-defined list of options
 * parameter:
 *  rdi => string from CLI argument
 * return:
 *  eax => 1 (help option)
 *  eax => 0 (invalid)
 */
validate_option:
    movq %rdi, %r8
    movq %r8, %rdi
    movq $_help_option, %rsi
    movq $_help_len, %rdx
    movzbl (%rdx), %edx
    callq strcmp
    cmpq $0x00, %rax
    je .Lvalidate_help
.Lvalidate_no_match:
    movl $0x00, %eax
    retq
.Lvalidate_help:
    movl $0x01, %eax
    retq

/* ===========================================
 * compare two strings with each other
 *
 * parameter:
 *  rdi => string from CLI argument
 *  rsi => string from predefined value
 *  rdx => number of characters to compare
 *
 * return:
 *  eax => difference between both strings
 */
strcmp:
    pushq %r8
    pushq %rbx
    xorq %r8, %r8
    xorq %r11, %r11
    movq %rdi, %rbx
.Lstrcmp_loop:
    movzbl (%rbx), %r9d
    movq %r9, %rdi
    callq lowercase
    movq %rax, %r9
    movzbl (%rsi), %r10d
    movq %r10, %rdi
    callq lowercase
    movq %rax, %r10
    addq %r9, %r11
    subq %r10, %r11
    incq %rbx
    incq %rsi
    addq $0x01, %r8
    cmpq %rdx, %r8
    jb .Lstrcmp_loop
    movq %r11, %rax
    popq %rbx
    popq %r8
    retq

/* ===========================================
 * Lowercase a character
 *
 * parameter:
 *  rdi => character
 *
 * return:
 *  rax => lowercase letter / original character
 */
lowercase:
    cmpq $0x41, %rdi
    jl .Llowercase_return
    cmpq $0x5B, %rdi
    jl .Lupper_case
    jge .Llowercase_return
.Lupper_case:
    addq $0x20, %rdi
.Llowercase_return:
    movq %rdi, %rax
    retq
