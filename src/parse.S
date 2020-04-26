parseint:
    pushq %rbp

    /* rdi contains the pointer to the string
     * rsi contains the length of the string */

    /* get the correct power of 16 for the digit
     * rdi is the current length */
    callq power16

    /* multiply the digit with its power of 16 */

    /* add result to eax */
power16:
    pushq %rbp

parsestr:
    pushq %rbp

    /* get the length of the number */

    /* divide the number with x * 16^(len-1)
     * where x increases by one every cycle
     * until the result is 1 */

    /* save the digit into an array */

    /* substract the digit multiplied its power of 16
     * from the original number */

    /* loop until the number is 0 */
