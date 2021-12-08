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

readarray -t lines < "input.txt"

counter=0
for line in "${lines[@]}" ; do
    right="${line//[a-z ]* | /}"

    read -ra words <<< "$right"

    for word in "${words[@]}" ; do
        letter_count="${#word}"
        case "$letter_count" in
        # 2->1
        # 4->4
        # 3->7
        # 7->8
        2 | 4 | 3 | 7)
            counter=$((counter+1))
            ;;
        esac
    done
done

echo $counter
