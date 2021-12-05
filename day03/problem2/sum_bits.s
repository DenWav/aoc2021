.intel_syntax noprefix

.data
.align 16

bad_input:
    .asciz "\ninvalid input"

.text
.global sum_bits

# Increment each of our 2 arrays (0's and 1's) depending on the bits of the input
#   rdi <- lines_buffer
#   rsi <- zeros_array
#   rdx <- ones_array
#   rcx <- length of the data
#   r8  <- number of lines in lines_buffer
sum_bits:
    push rax
    push r9
    push r10

    mov rax, rdi
    xor r9, r9                  # r9 will be our char index
    xor r10, r10                # r10 will be our line index

    jmp _clear_arrays

_sum_digit_loop:
    cmp byte ptr [rax+r9], '0'  # Check if the input is a 0
    je _handle_zero             # if so, handle it
    cmp byte ptr [rax+r9], '1'  # Check if the input is a 1
    je _handle_one              # if so, handle it

    call bad_input_error        # Unexpected input, quit
    ret

_handle_zero:
    inc word ptr [rsi+r9*2]     # Increment the 2 bytes corresponding with the current index
    jmp _sum_digit_lines_loop_finish_itr # finish iteration
_handle_one:
    inc word ptr [rdx+r9*2]     # Increment the 2 bytes corresponding with the current index
                                # finish iteration

_sum_digit_lines_loop_finish_itr:
    inc r9                      # Increment char index
    cmp r9, rcx                 # Check if we are at the end of this line
    jl _sum_digit_loop          # if not, read the next digit

    add rax, rcx
    inc r10                     # Increment line index
    cmp r10, r8                 # Check if we've seen all the lines
    jl _sum_digit_lines_loop_continue
    jmp _finish_sum_digit

_sum_digit_lines_loop_continue:
    xor r9, r9                  # Reset the char index
    jmp _sum_digit_loop         # Continue to next line

_finish_sum_digit:
    pop r10                     # Cleanup and return
    pop r9
    pop rax
    ret

_clear_arrays:
    push r10                    # We'll use r10 as our pointer
    xor r10, r10                # Initialize to 0

_clear_arrays_loop:
    mov word ptr [rsi+r10*2], 0 # Set the count to 0
    mov word ptr [rdx+r10*2], 0 # Set the count to 0

    inc r10                     # Next character
    cmp r10, rcx                # Check if there are more to set
    jl _clear_arrays_loop

    pop r10                     # Cleanup and
    jmp _sum_digit_loop

bad_input_error:
    lea rdi, [rip+bad_input]
    call _puts                  # Print out error message
    mov rax, 1                  # Return 1 (error)
    ret
