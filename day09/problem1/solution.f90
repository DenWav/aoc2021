module procedures
    implicit none

contains

    pure function is_lowpoint(values, i, j, rows, columns) result(res)
        implicit none

        integer, dimension(:, :), intent(in) :: values
        integer, intent(in) :: i, j, rows, columns
        logical :: res

        integer :: our_value

        res = .false.

        our_value = values(i, j)

        ! guard each case to make sure we don't reference out of bounds
        if (i /= 1) then
            if (values(i - 1, j) <= our_value) return
        end if
        if (i /= rows) then
            if (values(i + 1, j) <= our_value) return
        end if
        if (j /= 1) then
            if (values(i, j - 1) <= our_value) return
        end if
        if (j /= columns) then
            if (values(i, j + 1) <= our_value) return
        end if

        res = .true.
    end function
end module procedures


program solution
    use procedures
    implicit none

    integer :: unit = 1

    integer :: rows = 100
    integer :: columns = 100
    integer, dimension(:, :), allocatable :: values

    integer :: ios
    character(:), allocatable :: line

    integer :: i, j, parsed, file_id, danger_value_sum
    character :: c

    character(:), allocatable :: output_string

    open(unit, file = 'input.txt', status = 'old', iostat = ios)
    if (ios /= 0) stop 'Error reading input.txt'

    allocate(values(rows, columns))
    allocate(character(columns) :: line)

    ! Read all lines from the file
    i = 1
    do
        read(unit, '(A)', iostat = ios) line
        if (ios /= 0) exit

        do j = 1, columns
            c = line(j:j)

            read(c, *, iostat = ios) parsed
            if (ios /= 0) stop 'Error parsing input.txt'

            values(i, j) = parsed
        end do

        i = i + 1
    end do
    ! don't need to keep memory available for this anymore
    deallocate(line)

    if (i /= rows + 1) stop 'Unexpected number of lines read from input.txt'

    danger_value_sum = 0
    do concurrent (i = 1:rows)
        do concurrent (j = 1:columns)
            if (is_lowpoint(values, i, j, rows, columns)) then
                danger_value_sum = danger_value_sum + values(i, j) + 1
            end if
        end do
    end do

    i = int(log10(real(danger_value_sum))) + 1
    allocate(character(i) :: output_string)
    write(output_string, '(i0)') danger_value_sum
    print *, output_string

    deallocate(values)
end program solution
