# Written for and ran on Intel macOS
#
# clang *.s -o solution

# buffer has room for the strings of binary digits
# each line is 12 digits
#define DATA_SIZE 12
# but each line will also include a newline
#define BUFFER_SIZE DATA_SIZE + 1
#define ARRAY_SIZE DATA_SIZE * 2
#define LINES_COUNT 1000
#define LINES_SIZE DATA_SIZE * LINES_COUNT

.intel_syntax noprefix

.data
.align 16

input_buffer:
    .space BUFFER_SIZE
zeros_array:
    .space ARRAY_SIZE
ones_array:
    .space ARRAY_SIZE

# Who cares about space, take the "easy" route
lines_buffer:
    .space LINES_SIZE

o2_generator_value:
    .space DATA_SIZE
co2_scrubber_value:
    .space DATA_SIZE

printf_input:
    .asciz "%u\n"
read_error_msg:
    .asciz "\nerror reading from stdin"
incomplete_read_msg:
    .asciz "\ndata stopped unexpectedly"

.text

.global _main
_main:
    push rbp                    # Set up stack
    mov rbp, rsp
    push rbx                    # rbx has to be maintained as well (I don't know why)
    push rax                    # push an additional register to re-align the stack

    # registers passed into int function:
    # rdi, rsi, rdx, rcx, r8, r9

    lea r15, [rip+lines_buffer] # Index of lines_buffer

_program_loop:
    # Read input from stdin
    call _clear_buffer           # Make sure the buffer is clear
    xor rdi, rdi                # param0 <- 0 (stdin file descriptor)
    lea rsi, [rip+input_buffer] # param1 <- address of the buffer.
    mov rdx, BUFFER_SIZE        # param2 <- size of the buffer
    call _read                  # read(int fd, void *buf, size_t count)

    # Check our input status
    cmp rax, 0                  # Check if the call to read() returned 0
    je _after_program_loop      # which would indicate stdin is closed.
                                # If it's closed, print results

    # Handle error cases
    cmp rax, -1                 # Check if an error occured when we called
    jne _check_buffer_size      # read() - don't bother trying to handle it
    call read_error             # Print error message
    jmp _program_exit           # Quit

_check_buffer_size:
    cmp rax, BUFFER_SIZE        # Check if we got all the data we expected
    je _store_input
    call incomplete_read        # Print error message
    jmp _program_exit           # Quit

_store_input:
    mov rdi, r15              # Index into our lines buffer
    lea rsi, [rip+input_buffer] # param1 <- address of the buffer.
    mov rdx, DATA_SIZE          # buffer length
    call _memcpy                # Copy data
    add r15, DATA_SIZE          # Increment index

    jmp _program_loop

_after_program_loop:
    # Set up parameters for both reduce_lines calls
    lea rdi, [rip+lines_buffer]
    lea rsi, [rip+o2_generator_value]
    lea rdx, [rip+co2_scrubber_value]
    lea rcx, [rip+zeros_array]
    lea r8, [rip+ones_array]
    mov r9, DATA_SIZE
    mov r10, LINES_COUNT
    lea r12, [rip+input_buffer]

    mov r11, 0                  # reduce for o2
    call reduce_lines

    push rsi                    # rsi will be used again for the next reduce
    mov rsi, DATA_SIZE          # for convert we set it to the length
    call convert_string_to_int  # Convert the value at the top of lines_buffer
    pop rsi

    mov r13, rax                # Store the converted value

    mov r11, 1                  # reduce for co2
    call reduce_lines

    mov rsi, DATA_SIZE          # for convert we set rsi to the length
    call convert_string_to_int

_print_values:
    # Multiply the gamma and epsilon rates
    mul r13                     # Multiple co2 value  in rax (implicit destination of mul)
                                # with o2 value in r13

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
_clear_buffer:
    lea rsi, [rip+input_buffer] # find the address of the buffer
    mov qword ptr [rsi], 0      # set the first 8 bytes to 0
    mov dword ptr [rsi+8], 0    # and the next 4 to 0
    mov byte ptr [rsi+12], 0    # and the last byte to 0
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
