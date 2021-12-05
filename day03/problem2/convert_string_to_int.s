.intel_syntax noprefix

.text
.global convert_string_to_int

# Converts the binary string referenced by rdi to an integer
# stored in rax
#   rdi <- binary string pointer
#   rsi <- length of the string in bytes
convert_string_to_int:
    push rbx
    push rdi                    # We will be incrementing this pointer in the loop

    xor rax, rax                # We will store the output in rax

    mov rbx, rdi                # Set up rbx as our limit pointer
    add rbx, rsi

_convert_string_to_int_loop:
    shl rax                     # Shift bits left - initial is fine since rax is 0

    cmp byte ptr [rdi], '0'
    je _convert_string_to_int_loop_continue

    inc rax                     # If the value wasn't 0, it's 1, so increment rax

_convert_string_to_int_loop_continue:
    inc rdi                     # Go to the next digit
    cmp rdi, rbx                # Check if there are more digits
    jl _convert_string_to_int_loop

    pop rdi                     # Cleanup and return
    pop rbx
    ret
