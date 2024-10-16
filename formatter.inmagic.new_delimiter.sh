#!/bin/bash

myself_name=$(basename $0)

if [[ -z "$1" ]]
then
    echo_2 "Param 1 is the InMagic csv file."
    exit 1
fi

new_delimiter="~"
while getopts o: cmdln_opt
do
    case $cmdln_opt in
    (o)     new_delimiter="$OPTARG"
            ;;
    (*)     echo_2 "Invalid option: ${cmdln_opt}"
#           display_usage
            exit 1
            ;;
   esac
done
shift $(expr $OPTIND - 1)

filename="$1"
if grep -i "${new_delimiter}" "${filename}" >/dev/null
then
    echo_2 "Output delimiter '${new_delimiter}' present in input file, aborting..."
    exit 1
fi
filename_prefix="${myself_name%.*}.$(basename ${filename%.*})"

#       InMagic has a trailing comma, so the sed removes it as the convertto-csv doesn't put it there.
#       dos2unix -O "${filename}" | sed -e 's/,\s*$//' |  (or... maybe not...)
(   set -x
    dos2unix -O "${filename}" | \
                              tee ${filename_prefix}.before |\
                              do_pwsh -x "\$input | convertfrom-csv | convertto-csv -delimiter ',' -usequotes asneeded" \
                              > ${filename_prefix}.after 
    cmp -b ${filename_prefix}.before ${filename_prefix}.after
)
rc=$?
if [[ ${rc} -ne 0 ]]
then
    exit $rc
fi

(   set -x
    dos2unix -O "${filename}" | \
                              do_pwsh -x "\$input | convertfrom-csv | convertto-csv -delimiter '${new_delimiter}' -usequotes asneeded" \
                              > "${filename%.*}.new_delimiter.csv"
)
