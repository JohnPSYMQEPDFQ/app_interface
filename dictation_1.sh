#!/usr/bin/bash

myself_name=$(basename $0)

function display_usage {
    echo "Usage: ${myself_name} [-cgm] [-s ead_id] [-t title] file"
    echo "       -c = Tell the add_objects program to combine-like-records."
    echo "       -e = Run the csv creation program with the specified ead_id value."
    echo "       -g = Minimum number of records need to make a group (default is 2)."
    echo "       -l = Maximum number of group levels (default is 5)."
    echo "       -p = Phrase split characters (default is ':.')."
    echo "       -s = Maximum number of series records (default is 0)."
    echo "       -t = The indenter will create a new_parent record with the specified title."
    echo "       -I = DON'T run the indent prgm (the 1st one), don't remove the *txt files either."
    echo "       -S = do sort"
    echo "       Param 1 is the file to process." 
} 

combine_like_records=''  #  -c
ead_id=''                #  -e X
min_group_size=''        #  -g N      formatter.indent.to.add_objects.rb default is 2
max_group_levels=''      #  -l N      formatter.dictation_1.to.indent.rb default is 12
phrase_split_chars=''    #  -p 'XXX'  formatter.dictation_1.to.indent.rb default is ':.'
max_series_records=''    #  -s N      formatter.indent.to.add_objects.rb default is 0
parent_title=''          #  -t X
do_sort=''               #  -S
do_indent_prgm='1'       #  -I = don't do the indent program, don't remove files at the beginning.

while getopts ce:g:l:p:s:t:IS cmdln_opt
do
    case $cmdln_opt in
    (c)     combine_like_records='1'
            ;;
    (e)     ead_id="$OPTARG"
            ;;
    (g)     min_group_size="$OPTARG"
            ;;
    (l)     max_group_levels="$OPTARG"
            ;;
    (p)     phrase_split_chars="$OPTARG"
            ;;
    (s)     max_series_records="$OPTARG"
            ;;
    (t)     parent_title="$OPTARG"
            ;;
    (I)     do_indent_prgm=''
            ;;
    (S)     do_sort='1'
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
input_fn="$1"
if [[ "${input_fn:0:1}" == '.' ]]
then
    input_fn="$(basename $PWD)${input_fn}"
fi
if [[ ! -a "${input_fn}" ]] 
then
    echo "Can't find file: '${input_fn}'" 1>&2
    exit 3
fi
if [[ -n "${ead_id}" && -n "${combine_like_records}" ]]
then
    {
        echo "The -c and -s options won't work together" 
        echo "as the 'csv' program can't handle more than one date per record."
    } 1>&2
    exit 4
fi
output_fn_prefix="${myself_name%.*}.${input_fn%.*}"
shopt -s nocaseglob     # Options are NOT inheried, and this is needed to glob files when the pattern contains upper cases.
rm -v ${output_fn_prefix}.*.err 
if [[ -n "${do_indent_prgm}" ]]
then
    rm -v ${output_fn_prefix}.*.txt
    rm -v ${output_fn_prefix}.*.json
fi 

function trap_0 {
    echo "Last rc=$?"
    if [[ -a "${output_fn_prefix}.formatter.err" ]] 
    then
        echo '========================================'
        echo '   Formatter results:'
        echo ''
        cat "${output_fn_prefix}.formatter.err"
    fi
    if [[ -a "${output_fn_prefix}.indent.err" ]] 
    then
        echo '========================================'
        echo '   Indenter results:'
        echo ''
        cat "${output_fn_prefix}.indent.err"
    fi
    if [[ -n "${ead_id}" ]] 
    then
        if [[ -a "${output_fn_prefix}.spreadsheet.err" ]]
        then
            echo '========================================'
            echo '   csv creator results:'
            echo ''
            cat "${output_fn_prefix}.spreadsheet.err"
        fi
    fi
    echo 
    if [[ -e "${output_fn_prefix}.add_objects.SORTED.txt" && -e "${output_fn_prefix}.add_objects.UNSORTED.txt" ]]
    then
        echo "sdiff ${output_fn_prefix}.add_objects.SORTED.txt ${output_fn_prefix}.add_objects.UNSORTED.txt"
    fi
} 1>&2
trap 'trap_0' 0

if [[ -n "${do_indent_prgm}" ]]
then
    (   set -x
        run_ruby.sh formatter.dictation_1.to.indent.rb ${max_group_levels:+--max_group_levels }${max_group_levels} \
                                                       ${phrase_split_chars:+--phrase_split_chars }${phrase_split_chars} \
                                "${input_fn}" \
                               >"${output_fn_prefix}.indent.json" \
                              2>"${output_fn_prefix}.formatter.err"   \
                              3>"${output_fn_prefix}.formatter.title_text.txt"
    )
    [[ $? -gt 0 ]] && exit 5
fi
touch "${output_fn_prefix}.indent.err"
echo ""          >> "${output_fn_prefix}.indent.err"
echo "UNSORTED:" >> "${output_fn_prefix}.indent.err"
(   set -x
    run_ruby.sh formatter.indent.to.add_objects.rb ${combine_like_records:+--combine_like_records} \
                                                   ${min_group_size:+--min_group_size=}${min_group_size:+"${min_group_size}"} \
                                                   ${max_series_records:+--max_series=}${max_series_records:+"${max_series_records}"} \
                                                   ${parent_title:+--parent_title=}${parent_title:+"${parent_title}"} \
                                                   "${output_fn_prefix}.indent.json" \
               1> "${input_fn%.*}.add_objects.UNSORTED.json" \
               2>>"${output_fn_prefix}.indent.err" \
               3> "${output_fn_prefix}.indent.title_text.UNSORTED.txt"
)
[[ $? -gt 0 ]] && exit 6

if [[ -n "${do_sort}" ]]
then
    echo ""        >> "${output_fn_prefix}.indent.err"
    echo "SORTED:" >> "${output_fn_prefix}.indent.err"
    (   set -x
        sort -f "${output_fn_prefix}.indent.json" > "${output_fn_prefix}.indent.sorted.json"
        run_ruby.sh formatter.indent.to.add_objects.rb ${combine_like_records:+--combine_like_records} \
                                                       ${min_group_size:+--min_group_size=}${min_group_size:+"${min_group_size}"} \
                                                       ${max_series_records:+--max_series=}${max_series_records:+"${max_series_records}"} \
                                                       ${parent_title:+--parent_title=}${parent_title:+"${parent_title}"} \
                                                       "${output_fn_prefix}.indent.sorted.json" \
               1> "${input_fn%.*}.add_objects.SORTED.json" \
               2>>"${output_fn_prefix}.indent.err" \
               3> "${output_fn_prefix}.indent.title_text.SORTED.txt"
    )
    [[ $? -gt 0 ]] && exit 7
fi

if [[ -n "${ead_id}" ]] 
then
    (   set -x
        run_ruby.sh spreadsheet.add_objects.to.csv.rb --ead "${ead_id}" "${input_fn%.*}.add_objects.UNSORTED.txt" 2>"${output_fn_prefix}.spreadsheet.err" >"${input_fn%.*}.AS_spreadsheet.csv" 
    )
fi
[[ $? -gt 0 ]] && exit 8

exit 0

