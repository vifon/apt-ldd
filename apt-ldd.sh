#!/bin/bash

# apt-ldd.sh --- Get the packages containing the missing shared libraries

# Copyright (C) 2015 Wojciech Siewierski <wojciech dot siewierski at onet dot pl>

# Author: Wojciech Siewierski <wojciech dot siewierski at onet dot pl>

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

usage()
{
    cat <<EOF
Usage:
    $ $0 -h
    $ ldd <file> | $0 [-a <architecture>]
    $ $0 -f <file> [-a <architecture>]
EOF
}

ARCH=$(dpkg --print-architecture)

while getopts "a:f:h" ARG; do
    case "$ARG" in
        a)
            ARCH=$OPTARG
            ;;
        f)
            FILE=$OPTARG
            ;;
        h)
            usage
            exit
            ;;
        ?)
        ;;
    esac
done
shift $((OPTIND-1))

if [ -t 0 -a -z "$FILE" ]; then
    usage
    exit
fi

find_missing_shared_libs()
{
    awk '/not found/ { print $1 }' |
        parallel -j10 'apt-file search {} | head -n1' |
        uniq |
        perl -pe '
BEGIN { $arch = shift }
s/:.*$/:$arch/
' -- "$1"
}

if [ -n "$FILE" ]; then
    ldd "$FILE" | find_missing_shared_libs "$ARCH"
else
    find_missing_shared_libs "$ARCH"
fi
