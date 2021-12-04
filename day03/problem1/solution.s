# Written for and ran on Intel macOS
#
# > clang solution.s -o solution
# > ./solution < input.txt

# buffer has room for the strings of binary digits
# each line is 12 digits
#define DATA_SIZE 12
# but each line will also include a newline
#define BUFFER_SIZE DATA_SIZE + 1
# arrays of 2 bytes each
#define ARRAY_SIZE DATA_SIZE * 2

.intel_syntax noprefix

.data
.align 16

input_buffer:
    .space BUFFER_SIZE
zeros_array:
    .space ARRAY_SIZE
ones_array:
    .space ARRAY_SIZE
printf_input:
    .asciz "%u\n"
read_error_msg:
    .asciz "\nerror reading from stdin"
incomplete_read_msg:
    .asciz "\ndata stopped unexpectedly"
bad_input:
    .asciz "\ninvalid input"

.text

.global _main
_main:
    push rbp                    # Set up stack
    mov rbp, rsp
    push rbx                    # rbx has to be maintained as well (I don't know why)
    push rax                    # push an additional register to re-align the stack

_program_loop:
    # Read input from stdin
    call clear_buffer           # Make sure the buffer is clear
    xor rdi, rdi                # param0 <- 0 (stdin file descriptor)
    lea rsi, [rip+input_buffer] # param1 <- address of the buffer.
    mov rdx, BUFFER_SIZE        # param2 <- size of the buffer
    call _read                  # read(int fd, void *buf, size_t count)

    # Check our input status
    cmp rax, 0                  # Check if the call to read() returned 0
    je print_output             # which would indicate stdin is closed.
                                # If it's closed, print results

    # Handle error cases
    cmp rax, -1                 # Check if an error occured when we called
    jne _check_buffer_size      # read() - don't bother trying to handle it
    call read_error             # Print error message
    jmp _program_exit           # Quit

_check_buffer_size:
    cmp rax, BUFFER_SIZE        # Check if we got all the data we expected
    je _count_input
    call incomplete_read        # Print error message
    jmp _program_exit           # Quit

_count_input:
    call sum_bits               # Increment the zeros and ones arrays based on input
    cmp rax, -1                 # If sum_bits returns -1, that indicates an error
    je _program_exit            # so quit.
    jmp _program_loop           # Otherwise, continue the program loop

print_output:
    # We need to turn our byte arrays into numbers
    # Each byte in the array refers to a count of bits, and
    # each count, compared with the other array, determines i
    # the bit in that location is a 1 or a 0

    xor r8, r8                  # r8 will store the gamma rate (most common)
    xor r9, r9                  # r9 will store the epsilon rate (least common)

    xor ax, ax                  # ax will hold the single zeros value
    xor bx, bx                  # bx will hold the single ones value

    xor r10, r10                # r10 will be our counting index

    lea rdi, [rip+zeros_array]  # rdi will be our zeros array
    lea rsi, [rip+ones_array]   # rsi will be our ones array

_compute_output_loop:
    # Shift the bits of both of our integer values 1 to the left
    # This is okay to do on the first iteration because the value
    # for both registers was already set to 0.
    shl r8, 1
    shl r9, 1

    mov ax, [rdi+r10]           # load the value from the zeros_array
    mov bx, [rsi+r10]           # load the value from the ones_array

    cmp ax, bx                  # Check if there are more 1s or 0s
    jg _epsilon_incr
_gamma_incr:
    inc r8                      # There are more 1s, so increment gamma
    jmp _prepare_next_itr

_epsilon_incr:
    inc r9                      # There are more 0s, so increment epsion

_prepare_next_itr:
    add r10, 2                  # Increment r8 by 2 as the values are 2 bytes wide
    cmp r10, ARRAY_SIZE         # Check if we are at the end
    jl _compute_output_loop     # If not, go again

_print_values:
    # Multiply the gamma and epsilon rates
    mov rax, r8                 # Set rax (implicit destination of mul) to the gamma rate
    mul r9                      # Multiply that by the epsilon rate

    # use printf to easily print our integer as decimal
    lea rdi, [rip+printf_input] # Load the printf string input
    mov rsi, rax                # Load our numerical result
    mov al, 1                   # We are passing 1 extra argument to printf
    call _printf                # printf(const char *restrict format, ...)

    xor rax, rax                # Return 0 (success)

_program_exit:
    pop rbx                     # Pop the rax push done at the beginning for stack alignment
    pop rbx                     # Some cleanup. I don't know why rbx must be preserved,
    leave                       # But it segfaults without it
    ret

# Set the contents of the buffer to 0
clear_buffer:
    lea rsi, [rip+input_buffer] # find the address of the buffer
    mov qword ptr [rsi], 0      # set the first 8 bytes to 0
    mov dword ptr [rsi+8], 0    # and the next 4 to 0
    mov byte ptr [rsi+12], 0    # and the last byte to 0
    ret

# Increment each of our 2 arrays (0's and 1's) depending on the bits of the input
sum_bits:
    xor rax, rax                # index
    lea rbx, [rip+input_buffer] # address of the buffer
    lea rcx, [rip+zeros_array]  # address of the zeros array
    lea rdx, [rip+ones_array]   # address of the ones array

_sum_digit:
    mov r8, rax                 # r8 will be the byte address we use to increment
                                # the value, so we set it to rax, which is our index

    cmp BYTE PTR [rbx], '0'     # Check if the input is a 0
    je _handle_zero             # if so, handle it
    cmp BYTE PTR [rbx], '1'     # Check if the input is a 1
    je _handle_one              # if so, handle it

    call bad_input_error        # Unexpected input, quit
    ret

_handle_zero:
    inc word ptr [rcx + r8]     # Increment the 2 bytes corresponding with the current index
    jmp _finish_sum_digit       # finish iteration

_handle_one:
    inc word ptr [rdx + r8]     # Increment the 2 bytes corresponding with the current index
                                # finish iteration

_finish_sum_digit:
    add rax, 2                  # Increment index by 2 as the values are 2 bytes wide
    inc rbx                     # Only increment input index by 1
    cmp rax, ARRAY_SIZE         # Check if we are at the end
    jl _sum_digit               # if not, read the next digit
    xor rax, rax                # We're done, so return 0 back to the caller
    ret

# Error messages
incomplete_read:
    lea rdi, [rip+incomplete_read_msg]
    call _puts                  # Print out error message
    mov rax, 1                  # Return 1 (error)
    ret

read_error:
    lea rdi, [rip+read_error_msg]
    call _puts                  # Print out error message
    mov rax, 1                  # Return 1 (error)
    ret

bad_input_error:
    lea rdi, [rip+bad_input]
    call _puts                  # Print out error message
    mov rax, 1                  # Return 1 (error)
    ret
