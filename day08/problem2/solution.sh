#!/usr/bin/env bash
#
# Copyright (c) 2021 Kyle Wood (DenWav)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, version 3 only.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#

#  ┌─┐   │  ──┐  ──┐  │ │  ┌──  ┌──  ──┐  ┌─┐  ┌─┐
#  │ │   │  ┌─┘  ──┤  └─┤  └─┐  ├─┐    │  ├─┤  └─┤
#  └─┘   │  └──  ──┘    │  ──┘  └─┘    │  └─┘   ─┘

# 0=6 ; 1=2 ; 2=5
# 3=5 ; 4=4 ; 5=5
# 6=6 ; 7=3 ; 8=7
# 9=6

#    aaaa
#   b    c
#   b    c
#    dddd
#   e    f
#   e    f
#    gggg

readarray -t lines < "input.txt"

result_sum=0
for line in "${lines[@]}" ; do
    left="${line// | [a-z ]*/}"
    right="${line//[a-z ]* | /}"

    read -ra signal_words <<< "$left"
    read -ra display_words <<< "$right"

    # We can determine every other possible number using only one and four
    one_letters=""
    four_letters=""

    for word in "${signal_words[@]}" ; do
        letter_count="${#word}"
        case "$letter_count" in
        2) # signal is 1
            one_letters="$word"
            ;;
        4) # signal is 4
            four_letters="$word"
            ;;
        3 | 5 | 6 | 7)
            # 3 -> signal is 7
            # 5 -> signal is 2, 3, or 5
            # 6 -> signal is 0, 6, or 9
            # 7 -> signal os 8
            ;;
        esac
    done

    lonely_four_letters="$four_letters"
    lonely_four_letters="${lonely_four_letters//${one_letters:0:1}}"
    lonely_four_letters="${lonely_four_letters//${one_letters:1:1}}"

    digits=""
    for word in "${display_words[@]}" ; do
        letter_count="${#word}"
        case "$letter_count" in
        2) # signal is 1
            digits="${digits}1"
            ;;
        3) # signal is 7
            digits="${digits}7"
            ;;
        4) # signal is 4
            digits="${digits}4"
            ;;
        7) # signal is 8
            digits="${digits}8"
            ;;
        5) # signal is 2, 3, or 5

            # 3 is the only value here which has both one letters
            if [[ "$word" = *"${one_letters:0:1}"* ]] && [[ "$word" = *"${one_letters:1:1}"* ]] ; then
                digits="${digits}3"
            # 5 has both of the non-one letters from the four letters
            elif [[ "$word" = *"${lonely_four_letters:0:1}"* ]] && [[ "$word" = *"${lonely_four_letters:1:1}"* ]] ; then
                digits="${digits}5"
            # The only other options is 2
            else
                digits="${digits}2"
            fi

            ;;
        6) # signal is 0, 6, or 9

            # 6 is the only value here which doesn't have both one letters
            if [[ "$word" != *"${one_letters:0:1}"* ]] || [[ "$word" != *"${one_letters:1:1}"* ]] ; then
                digits="${digits}6"
            # 9 has all of the four letters
            elif [[ "$word" = *"${four_letters:0:1}"* ]] && [[ "$word" = *"${four_letters:1:1}"* ]] \
                    && [[ "$word" = *"${four_letters:2:1}"* ]] && [[ "$word" = *"${four_letters:3:1}"* ]] ; then
                digits="${digits}9"
            # The only other options is 0
            else
                digits="${digits}0"
            fi

            ;;
        esac
    done

    echo "$digits"

    result_sum="$((10#$result_sum + 10#$digits))"
done

echo
echo
echo $result_sum
