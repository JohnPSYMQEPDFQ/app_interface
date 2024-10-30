#!/usr/bin/bash

myself_name=$(basename $0)

function display_usage {
    echo "Usage: ${myself_name} [-c 'columns'] [-d X ] [-D] [-s] file"
    echo "       -c = The --columns option is passed to the 'formatter.inmagic_to_dictation_1.rb' program."
    echo "            Enclose the entire columns string in quotes which allows for spaces in the column names."
    echo "       -d = The new delimiter for internal processing in 'formatter.inmagic_to_dictation_1.rb', default is '~'."
    echo "       -D = Skip the pwsh JSON script if the JSON file is present."
    echo "       -s = The --sort option is passed to the 'formatter.inmagic_to_dictation_1.rb' program." 
    echo "       Param 1 is the file to process." 
}

columns=""
new_delimiter="~"
run_json_script="1"
sort_detail=""
while getopts c:Ds cmdln_opt
do
    case $cmdln_opt in
    (c)     columns="'$OPTARG'"
            series_name=""
            IFSSAVE="$IFS"
            IFS=,                           # <<<<< DANGER
            columns_A=( $OPTARG )
            for column in ${columns_A[*]}
            do
                IFS=:                       # <<<<< DANGER
                column_name_and_use=( ${column} )
#               echo "column_name_and_use='${column_name_and_use}'"
                column_name=${column_name_and_use[0]}
                column_name=${column_name## }
                column_name=${column_name%% }
                column_use=${column_name_and_use[1]}
                column_use=${column_use## }
                column_use=${column_use%% }
#               echo "column_name='${column_name}' column_use='${column_use}'"
                if [[ ${column_use} == 'series' ]]
                then
                    series_name=${column_name}
                    break
                fi
            done
            IFS="${IFSSAVE}"                # <<<<< DANGER
            ;;
    (D)     run_json_script=""
            ;;
    (s)     sort_detail="--sort"
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
filename="$1"
filename_prefix="${myself_name%.*}.${filename%.*}"
shopt -s nocaseglob     # Options are NOT inheried, and this is needed to glob files when the pattern contains upper cases.
rm "${filename_prefix}".*
touch "${filename_prefix}.err"

function trap_0 {
    echo "Last rc=$?"
    cat "${filename_prefix}.err"
} 1>&2
trap 'trap_0' 0

if [[ -z "${run_json_script}" && -e "${filename_prefix}.json.txt" ]] 
then
    echo ""
    echo "The '${filename_prefix}.json.txt' file exists, skipping the 'csv-to-json' step."
    ls -la "${filename_prefix}.json.txt"
    echo ""
    echo ""
else
    if grep -i "${new_delimiter}" "${filename}" 
    then
        echo_2 "Output delimiter '${new_delimiter}' present in '${filename}' file, aborting..."
        exit 4
    fi
   
    (   echo "\$csv = import-csv -path '${filename}'"
        if [[ -n "${series_name}" ]]
        then
            echo "\$csv = \$csv | sort '${series_name}'"
        fi
        echo "\$csv | convertto-json -compress | out-file '${filename_prefix}.json.compress.txt'"
        echo "\$csv | convertto-json           | out-file '${filename_prefix}.json.txt'"
    ) | do_pwsh -x 2>> "${filename_prefix}.err" 
    dos2unix "${filename_prefix}.json.compress.txt" 
    [[ $? -gt 0 ]] && exit 5
fi

(   set -x
    eval run_ruby.sh formatter.inmagic.to.dictation_1.rb ${sort_detail} ${columns:+--columns }${columns} "${filename_prefix}.json.compress.txt" \
                     > "${filename%.*}.FORMATTED.txt" 2>> "${filename_prefix}.err"
)
[[ $? -gt 0 ]] && exit 6

exit 0

