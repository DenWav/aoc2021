.intel_syntax noprefix

.text
.global copy_matched_lines

# Find all rows which match the input up to the specified length
# up to the top of the list
copy_matched_lines:
    #  rdi <- line to match
    #  rsi <- lines_buffer
    #  rdx <- count of letters to match
    #  rcx <- width of a single line
    #  r8  <- line count
    #  r9  <- temp_buffer
    # Returns count of matches in rax

    push r10
    push r11
    push r12                    # index

    xor r12, r12                # Init index to 0
    mov r10, rsi                # we will use r10 as the reference for the start of lines_buffer
    xor r11, r11                # The index of the copy location

_copy_matched_lines_loop:
    mov bl, [rdi+rdx]           # Store the char from rdi into bl
    cmp byte ptr [rsi+rdx], bl  # And compare it with the char from rsi
    je _copy_row_to_index       # If they are the same, copy the line to the top

_copy_matched_lines_loop_continue:
    add rsi, rcx                # Move to the next line
    inc r12                     # Increment index
    cmp r12, r8                 # Check if there are more lines to check
    jl _copy_matched_lines_loop

_copy_matched_lines_loop_finish:
    mov rax, r11                # Return the count of matches

    pop r12                     # Cleanup and return
    pop r11
    pop r10
    ret

_copy_row_to_index:
    push rax
    push rdx
    push rdi

    # r10+r11*rcx
    mov rax, rcx                # width of a line
    mul r11                     # Multiply by r11, our copy index
    add rax, r10                # Add the reference of the start of lines_buffer

    # copy r10+r11*rcx to temp_buffer
    push rsi                    # store rsi
    mov rdi, r9                 # destination is temp_buffer
    mov rsi, rax                # source is r10+r11*rcx
    mov rdx, rcx                # length, will be used for all 3 memcpys
    call _call_memcpy
    pop rsi                     # remember rsi

    # copy rsi to r10+r11*rcx
    # rsi is already set to the source
    mov rdi, rax                # destination is r10+r11*rcx
    call _call_memcpy

    push rsi                    # store rsi
    # copy temp_buffer to rsi
    mov rdi, rsi                # dstination is rsi
    mov rsi, r9                 # source is temp_buffer
    call _call_memcpy

    pop rsi                     # Restore
    pop rdi
    pop rdx
    pop rax

    inc r11                     # Incrment the copy index

    jmp _copy_matched_lines_loop_continue

_call_memcpy:
    # memcpy seems to screw with all kinds of registers
    # So just to be on the safe side...
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    call _memcpy

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    ret
