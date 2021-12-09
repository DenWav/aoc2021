! This code is really slow and inefficient
! There's so many ways I wanted to use proper data structures to solve these problems more efficiently
! but learning and writing fortran was hard enough by itself
! Good news! This code is slow, but Fortran is fast
!
! And this still only produces a 50kb binary on macOS
module procedures
    implicit none

contains

    ! Go over the whole visited array up to visited_index looking for the specified index.
    ! Returns `true` if the index is already present, `false` if otherwise.
    ! We iterate over the whole array here since we don't know which order any particular
    ! point might be entered - it would be possible for a path to wrap around and find an
    ! item that isn't at the top of the list, for example.
    pure function did_visit(visited, visited_index, i, j) result(res)
        implicit none

        complex, dimension(:), intent(in) :: visited
        integer, intent(in) :: visited_index, i, j
        logical :: res

        integer :: index, x, y

        res = .false.

        do index = 1,visited_index
            x = int(realpart(visited(index)))
            y = int(imagpart(visited(index)))

            if (i == x .and. j == y) then
                res = .true.
                return
            end if
        end do
    end function did_visit

    ! Visit the specified index at (i, j) and "flow" outward from there, visiting as many indecies as far as possible.
    pure recursive subroutine flow(values, i, j, rows, columns, size, sum, visited, visited_index)
        implicit none

        integer, dimension(:,:), intent(in) :: values
        integer, intent(in) :: i, j, rows, columns

        integer, intent(out) :: size, sum

        complex, dimension(:), intent(inout) :: visited
        integer, intent(inout) :: visited_index

        integer :: called_size, called_sum

        ! start with nothing
        size = 0
        sum = 0

        if (i == 0 .or. j == 0 .or. i == rows + 1 .or. j == columns + 1) then
            ! we are out of bounds this is an illegal point
            return
        end if

        if (values(i, j) == 9) then
            ! 9 values cannot be in a basin
            return
        end if

        ! so inefficient, but fortran is hard enough to deal with as it is
        if (did_visit(visited, visited_index, i, j)) then
            return
        end if

        visited(visited_index) = cmplx(i, j)
        visited_index = visited_index + 1

        ! We are definitely staying here, so count ourself
        size = 1
        sum = values(i, j)

        ! Ask each neighbor
        call flow(values, i - 1, j, rows, columns, called_size, called_sum, visited, visited_index)
        size = size + called_size
        sum = sum + called_sum

        call flow(values, i + 1, j, rows, columns, called_size, called_sum, visited, visited_index)
        size = size + called_size
        sum = sum + called_sum

        call flow(values, i, j - 1, rows, columns, called_size, called_sum, visited, visited_index)
        size = size + called_size
        sum = sum + called_sum

        call flow(values, i, j + 1, rows, columns, called_size, called_sum, visited, visited_index)
        size = size + called_size
        sum = sum + called_sum
    end subroutine flow

    ! Keep the biggest sizes in a length-3 array, with the biggest at index 1, second biggest at index 2, and third
    ! biggest at index 3. This function does a little shifting around to make sure that order is always maintained.
    pure subroutine set_biggest(size, sum, biggest_sizes, biggest_sums)
        implicit none

        integer, intent(in) :: size, sum
        integer, dimension(3), intent(inout) :: biggest_sizes, biggest_sums

        integer :: i, shift, shift_tmp, sum_shift, sum_tmp

        ! shift the highest values if needed, keeping biggest at 1, 2nd at 2, and 3rd at 3
        shift = -1
        do i = 1,3
            if (shift >= 0) then
                shift_tmp = biggest_sizes(i)
                sum_tmp = biggest_sums(i)
                biggest_sizes(i) = shift
                biggest_sums(i) = sum_shift
                shift = shift_tmp
                sum_shift = sum_tmp
                cycle
            else if (biggest_sizes(i) < size) then
                shift = biggest_sizes(i)
                sum_shift = biggest_sums(i)
                biggest_sizes(i) = size
                biggest_sums(i) = sum
            end if
        end do
    end subroutine set_biggest

    ! Check if the sum of values is already listed in the top 3. The sum of the values is used as a sort of hash-code
    ! for sizes. Since we start filling from every index, we will fill the same basins multiple times. By remembing the
    ! sizes we can differentiate between basins which have the same size, but are seperate, vs the same basin one index
    ! apart.
    pure function is_size_present(sums, sum) result(res)
        implicit none

        integer, dimension(3), intent(in) :: sums
        integer, intent(in) :: sum
        logical :: res

        integer :: i

        res = .false.

        do i = 1,3
            if (sums(i) == sum) then
                res = .true.
                return
            end if
        end do
    end function is_size_present
end module procedures

program solution
    use procedures
    implicit none

    ! Make these match the file size. Keeps things easy.
    integer :: rows = 100
    integer :: columns = 100
    integer, dimension(:, :), allocatable :: values

    integer :: ios
    character(:), allocatable :: line

    integer :: i, j, k, parsed, file_id, x, y
    character :: c

    integer :: size, sum
    integer, dimension(3) :: biggest_sizes, biggest_sums

    ! 10x max(rows, columns) seems fine
    integer :: visited_size = 1000
    complex, dimension(:), allocatable :: visited
    integer :: visited_index

    character(:), allocatable :: output_string

    open(1, file = 'input.txt', status = 'old', iostat = ios)
    if (ios /= 0) stop 'Error reading input.txt'

    allocate(values(rows, columns))
    allocate(character(columns) :: line)

    ! initialize
    do i = 1,3
        biggest_sizes(i) = 0
        biggest_sums(i) = 0
    end do

    ! Read all lines from the file
    i = 1
    do
        read(1, '(A)', iostat = ios) line
        if (ios /= 0) exit

        do j = 1, columns
            c = line(j:j)

            read(c, *, iostat = ios) parsed
            if (ios /= 0) stop 'Error parsing input.txt'

            values(i, j) = parsed
        end do

        i = i + 1
    end do
    close(1, status = 'keep')
    ! don't need to keep memory available for this anymore
    deallocate(line)

    if (i /= rows + 1) stop 'Unexpected number of lines read from input.txt'

    allocate(visited(visited_size))
    do k = 1,visited_size
        visited(k) = 0
    end do

    visited_index = 1
    do i = 1,rows
        do j = 1,columns
            call flow(values, i, j, rows, columns, size, sum, visited, visited_index)

            ! Don't store it if we already have this value
            if (is_size_present(biggest_sums, sum)) then
                cycle
            end if

            call set_biggest(size, sum, biggest_sizes, biggest_sums)

            ! reset
            do k = 1,visited_size
                visited(k) = 0
            end do
            visited_index = 1
        end do
    end do
    deallocate(visited)

    size = 1
    do i = 1,3
        size = size * biggest_sizes(i)
    end do

    i = int(log10(real(size))) + 1
    allocate(character(i) :: output_string)
    write(output_string, '(i0)') size
    print *, output_string

    deallocate(values)
end program solution
