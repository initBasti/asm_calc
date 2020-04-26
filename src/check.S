stringcheck:
    pushq %rbp
    movq %rsp, %rbp
    movzbl (%rdi), %eax /* move the last 32bit of rdi into eax with zero extension*/
    testb %al, %al /* if the char is a null terminator return 0 */
    je .scexit_success

    subl $48, %eax /* reduce eax by 48 (ascii '0') */
    cmpb $9, %al /* if AL(low 8 bit of eax) > 8 (48+9=57 => ascii:9) return 1 */
    ja .scexit_fail
    incq %rdi /* move pointer by 1 */

.next:
    movzbl (%rdi), %eax
    testb %al, %al
    je .scexit_success
    incq %rdi

    subl $48, %eax
    cmpb $9, %al /* when char - 48 is smaller or equal to 9 it is a number */
    jbe .next

    movl $1, %eax /* if char -48 > 9 return 1 */
    ret

.scexit_success:
    movl $0x00, %eax
    popq %rbp
    ret

.scexit_fail:
    movl $0x01, %eax
    popq %rbp
    ret
    
opcheck:
    pushq %rbp

    cmpb $0x2B, %dil
    je .ocexit_success
    cmpb $0x2D, %dil
    je .ocexit_success

    movl $1, %eax
    popq %rbp
    ret

.ocexit_success:
    movl $0, %eax
    popq %rbp
    ret
