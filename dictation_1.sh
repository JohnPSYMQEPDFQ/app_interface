#!/usr/bin/bash

myself_name=$(basename ${0%.*})

function display_usage {
    echo "Usage: ${myself_name} [-cgm] [-s ead_id] [-t title] file"
    echo "       -c = Tell the add_objects program to combine-like-records."
    echo "       -g = Maximum number of levels for grouping (default is 3)."
    echo "       -m = Maximum number of series records (default is 0)."
    echo "       -s = Run the csv creation program with the specified ead_id value."
    echo "       -t = The indenter will create a new_parent record with the specified title."
    echo "       Param 1 is the file to process." 
} 1>&2

combine_like_records=""
max_group_levels=3
max_series_records=0
ead_id=""
parent_title=""

while getopts cg:m:s:t: cmdln_opt
do
    case $cmdln_opt in
    (c)     combine_like_records="1"
            ;;
    (g)     max_group_levels="$OPTARG"
            ;;
    (m)     max_series_records="$OPTARG"
            ;;
    (s)     ead_id="$OPTARG"
            ;;
    (t)     parent_title="$OPTARG"
            ;;
    (*)     display_usage
            exit 1
            ;;
    esac
done
shift $(expr $OPTIND - 1)
if [[ -z "$1" ]] 
then
    echo "No file parameter provided." 1>&2
    display_usage
    exit 2
fi
if [[ -n "$2" ]] 
then
    echo "Extra parameter found: '$2'" 1>&2
    display_usage
    exit 2
fi
if [[ ! -a "$1" ]] 
then
    echo "Can't find file: '$1'" 1>&2
    exit 3
fi
if [[ -n "${ead_id}" && -n "${combine_like_records}" ]]
then
    {
        echo "The -c and -s options won't work together" 
        echo "as the 'cvs' program can't handle more than one date per record."
    } 1>&2
    exit 4
fi
file_name="$1"
rm ${myself_name}.*.err ${myself_name}.*.txt

(   set -x
    run_ruby.sh formatter.txt.to.indent.dictation_1.rb --max_levels=${max_group_levels} \
                                                       "${file_name}" \
                2>"${myself_name}.formatter.err" >"${myself_name}.${file_name%.*}.indent.txt"
    sort -f "${myself_name}.${file_name%.*}.indent.txt" | \
    run_ruby.sh formatter.indent.to.add_objects.generic.rb ${combine_like_records:+--combine-like-record} \
                                                           ${max_series_records:+--max-series=}${max_series_records} \
                                                           ${parent_title:+--parent_title=}${parent_title:+"${parent_title}"} \
               2>"${myself_name}.indent.err" >"${myself_name}.${file_name%.*}.add_objects.txt"
    if [[ -n "${ead_id}" ]] 
    then
        run_ruby.sh spreadsheet.add_objects.to.csv.rb --ead "${ead_id}" "${myself_name}.${file_name%.*}.add_objects.txt" 2>"${myself_name}.spreadsheet.err" >"${myself_name}.${file_name%.*}.csv" 
    fi
    )
{
    echo '========================================'
    echo '   Formatter results:'
    echo ''
    cat "${myself_name}.formatter.err"
    echo '========================================'
    echo '   Indenter results:'
    echo ''
    cat "${myself_name}.indent.err"
    if [[ -n "${ead_id}" ]] 
    then
        echo '========================================'
        echo '   cvs creator results:'
        echo ''
        cat "${myself_name}.spreadsheet.err"
    fi
} 1>&2

