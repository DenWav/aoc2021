.intel_syntax noprefix

.text
.global compute_output

# Determine the expected bits for both o2 and co2
#   rdi <- zeros_array
#   rsi <- ones_array
#   rdx <- o2_generator_value
#   rcx <- co2_scrubber_value
#   r8  <- data length
compute_output:
    push rax                        # rax will hold a single zero value
    push rbx                        # rbx will hold a single one value
    push r9                         # r9 will be our counter

    xor ax, ax                      # ax will hold the single zeros value
    xor bx, bx                      # bx will hold the single ones value
    xor r9, r9                      # r9 will our counter

_compute_output_loop:
    mov ax, [rdi+r9*2]              # load the value from the zeros_array
    mov bx, [rsi+r9*2]              # load the value from the ones_array

    cmp ax, bx                      # Check if there are more 1s or 0s
    jg _compute_output_more_zeros
    jle _compute_output_more_ones

_compute_output_more_zeros:
    # There are more 0s
    mov byte ptr [rdx+r9], '0'      # o2_generater
    mov byte ptr [rcx+r9], '1'      # co2_scrubber
    jmp _compute_output_loop_next_iter

_compute_output_more_ones:
    # count of 0s is less than or equal to count of 1s
    mov byte ptr [rdx+r9], '1'      # o2_generater
    mov byte ptr [rcx+r9], '0'      # co2_scrubber
    jmp _compute_output_loop_next_iter

_compute_output_loop_next_iter:
    inc r9                          # Increment to next character
    cmp r9, r8                      # Check if we are at the end
    jl _compute_output_loop         # If not, go again

    pop r9                          # Cleanup used registers and return
    pop rbx
    pop rax
    ret
