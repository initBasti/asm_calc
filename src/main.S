.globl main
.globl _help_option
.globl _help_len
.globl _option_bits
.globl _equation_array
.globl _equation_array_length

.section .rodata
invalidsequence: .string "Invalid sequence of elements\n"
invalidargument: .string "Invalid argument\n"
invalidoperator: .string "Invalid operator\n"
invalidnumber: .string "Invalid number\n"
insufficientarguments: .string "Insufficient amount of arguments\n"

help_text: .string "Assembly X64 calculator\nValid operators:\n'+' : [Addition] & '-' : [Subtraction]\n'x' : [Multiplication] & '/' : [Division]\n'^' : [Exponentiation] & 'R' : [nth Root of]\n\nExample: `calc 1 + 2 x 3 - 4`\n"
_help_option: .string "--help"
_help_len: .word 0x06

.data
    _option_bits: .word 0
    _equation_array: .quad 0
    _equation_array_length: .word 0

.text

.include "src/operation.S"
.include "src/print.S"

main:
    pushq %rbp
    movq %rsp, %rbp

    movl $1, %eax
    cmpl $4, %edi
    jb .Lprint_error_insufficient_arguments
    callq check_equation
    cmpb $1, %al
    je .Lprint_error_invalid_argument
    ja .Lprint_error_invalid_sequence

    movq (_option_bits), %rax
    cmpq $0x01, %rax
    je .Lhelp_option

    callq parse_equation
    cmpb $1, %al
    je .Lprint_error_invalid_number
    ja .Lprint_error_invalid_operator

    callq calculate_equation
    movq %rax, %rdi
    callq print_int
    callq linebreak
.Lexit:
    movq %rbp, %rsp
    popq %rbp
    movl $0x3C, %eax
    movl $0x00, %edi
    syscall
.Lerror_exit:
    movq %rbp, %rsp
    popq %rbp
    movl $0x3C, %eax
    movl $0x01, %edi
    syscall

.Lprint_error_invalid_number:
    movq $invalidnumber, %rdi
    callq print_str
    jmp .Lerror_exit
.Lprint_error_invalid_operator:
    movq $invalidoperator, %rdi
    callq print_str
    jmp .Lerror_exit
.Lprint_error_invalid_argument:
    movq $invalidargument, %rdi
    callq print_str
    jmp .Lerror_exit
.Lprint_error_invalid_sequence:
    movq $invalidsequence, %rdi
    callq print_str
    jmp .Lerror_exit
.Lprint_error_insufficient_arguments:
    movq $insufficientarguments, %rdi
    callq print_str
    jmp .Lerror_exit
.Lhelp_option:
    movq $help_text, %rdi
    callq print_str
    jmp .Lexit
