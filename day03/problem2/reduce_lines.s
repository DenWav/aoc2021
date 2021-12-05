.intel_syntax noprefix

.text
.global reduce_lines

reduce_lines:
    # rdi <- lines_buffer
    # rsi <- o2_generator_value
    # rdx <- co2_scrubber_value
    # rcx <- zeros_array
    # r8  <- ones_array
    # r9  <- line_width
    # r10 <- line_count
    # r11 <- is_o2_value (0 for o2, 1 for co2)
    # r12 <- temp_buffer

    push r10                        # We will change this as the line count is reduced
    push r11                        # We will change this to point to rsi or rdx
    push r13

    mov r13, 0                      # the index of the char to match, starting at 0

    # r11 will actually store the value we want to match
    cmp r11, 0                      # check if r11 is 0
    je _use_o2_value

_use_co2_value:
    # The caller wants to use co2
    mov r11, rdx                    # co2_scrubber_value
    jmp _reduce_lines_loop
_use_o2_value:
    # The caller wants to use o2
    mov r11, rsi                    # o2_generator_value

_reduce_lines_loop:
    call _call_sum_bits             # Determine bit counts
    call _call_compute_output       # Determine expected outputs
    call _call_copy_matched_lines   # Copy matched lines to the top

    cmp rax, 1                      # If only 1 line matched, we have found it
    je _reduce_lines_finish

    mov r10, rax                    # Set our new line count

    inc r13                         # Increment our length of chars to match
    cmp r13, r9                     # Check if we have reached the full length of the string
    jl _reduce_lines_loop           # If not, keep checking

    mov rax, 1                      # Return 1 for failure

_reduce_lines_found:
    xor rax, rax                    # Return 0 for success

_reduce_lines_finish:
    pop r13                         # Cleanup and return
    pop r11
    pop r10
    ret

_call_sum_bits:
    # We have to remove both o2_generator_value and co2_scrubber_value
    # for the call to sum_bits, and shift our other registers down
    push rsi
    push rdx
    push rcx
    push r8

    # rdi is already the lines_buffer
    mov rsi, rcx
    mov rdx, r8
    mov rcx, r9
    mov r8, r10
    call sum_bits

    pop r8
    pop rcx
    pop rdx
    pop rsi

    ret

_call_compute_output:
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    push r10
    push r11
    push r12

    # Some registers need to be swapped with each other below
    mov r10, r8                     # r8 is ones_array
    mov r11, rsi                    # rsi is o2_generator_value
    mov r12, rdx                    # rdx is co2_scrubber_value

    mov rdi, rcx                    # param 0 - zeros_array
    mov rsi, r10                    # param 1 - ones_array
    mov rdx, r11                    # param 2 - o2_generator_value
    mov rcx, r12                    # param 3 - co2_scrubber_value
    mov r8, r9                      # param 4 - data length
    call compute_output

    pop r12
    pop r11
    pop r10
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi

    ret

_call_copy_matched_lines:
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    push r9

    mov rsi, rdi                    # param 1 - lines_buffer
    mov rdi, r11                    # param 0 - o2_generator_value or co2_scrubber_value
    mov rdx, r13                    # param 2 - length to match
    mov rcx, r9                     # param 3 - line_width
    mov r8, r10                     # param 4 - line_count
    mov r9, r12                     # param 5 - temp_buffer
    call copy_matched_lines

    pop r9
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret
