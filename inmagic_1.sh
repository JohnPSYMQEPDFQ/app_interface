#!/usr/bin/bash

myself_name=$(basename $0)
shopt -s extglob

function display_usage {
    echo "Usage: ${myself_name} -b[next|prior] [-c 'columns'] [-d X ] [-D] [-s] file"
    echo "       -b = The --box_only_line option passed to 'formatter.inmagic_to_dictation_1.rb' program."
    echo "            This option is required."
    echo "       -c = The --columns option is passed to the 'formatter.inmagic_to_dictation_1.rb' program."
    echo "            Enclose the entire columns string in quotes which allows for spaces in the column names."
    echo "            The column names are case sensitive!!"
    echo "       -d = The new delimiter for internal processing in 'formatter.inmagic_to_dictation_1.rb', default is '~'."
    echo "       -D = Skip the pwsh JSON script if the JSON file is present."
    echo "       -s = The --sort option is passed to the 'formatter.inmagic_to_dictation_1.rb' program." 
    echo "       Param 1 is the file to process." 
    echo ""
    echo "       -h or -? for help"
    echo ""
    echo "Examples:"
    echo "   inmagic_1.sh -b next -c'Record Group Number:recordgrp,Series Name:series,Extent:seriesdate,Series Description:seriesnote,Box List:detail' file"
    echo "   inmagic_1.sh -b next -c'Series Name:series,Extent:seriesdate,Series Description:seriesnote,Box List:detail' file"    
    echo "   inmagic_1.sh -b next -c'Box List:detail' file"    
    echo ""
}
  
echo "NOTE!"
echo "    If the CSV input file needs to be edited, you can used the 'line --inmagic' script to create a new one."
echo "    The resulting CSV file will still be sorted by the pwsh script, and the 'formatter.inmagic.to.dictation_1.rb' program will still work."
echo ""

box_only_line=''
columns=""
new_delimiter="~"
run_json_script="1"
sort_detail=""
while getopts \?hb:c:Ds cmdln_opt
do
    case $cmdln_opt in
    (b)     box_only_line="${OPTARG}"
            if [[ "${box_only_line}" != @(next|prior) ]]
            then
                echo "The -b option argument should be 'next' or 'prior'"
                exit 1
            fi
            ;;
    (c)     columns="'$OPTARG'"
            recordgrp_column_name=""
            series_column_name=""
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
                if [[ ${column_use} == 'recordgrp' ]]
                then
                    recordgrp_column_name=${column_name}
#                   break
                fi
                if [[ ${column_use} == 'series' ]]
                then
                    series_column_name=${column_name}
#                   break
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
if [[ -z "${box_only_line}" ]] 
then
    echo_2 "The -b option is required"
    display_usage
    exit 2
fi
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
rm -v ${filename_prefix:=VAR_NOT_SET}.err       # Don't remove .* because the -D option won't work.
if [[ -n "${run_json_script}" ]]
then
    rm -v ${filename_prefix:=VAR_NOT_SET}.* 
fi
touch ${filename_prefix:=VAR_NOT_SET}.err

function trap_0 {
    echo "Last rc=$?"
    cat "${filename_prefix}.err"
} 1>&2
trap 'trap_0' 0

(   
    if [[ -z "${run_json_script}" && -s "${filename_prefix}.json" ]] 
    then
        echo ""
        echo "The '${filename_prefix}.json' file exists, skipping the 'csv-to-json' step."
        ls -la "${filename_prefix}.json"
        echo ""
        echo ""
    else
        if grep -i "${new_delimiter}" "${filename}" 
        then
            echo_2 "Output delimiter '${new_delimiter}' present in '${filename}' file, aborting..."
            exit 4
        fi
        
        sort_by=''      
        if [[ -n "${recordgrp_column_name}" ]]
        then
            sort_by="${sort_by} {\$value = (\$_.'${recordgrp_column_name}' -replace '\D', ''); if (\$value -eq '') { 0 } else { [int]\$value } },"
            sort_by="${sort_by} {\$_.'Collection Name' -replace '\s+', ' '},"
        fi
        if [[ -n "${series_column_name}" ]]
        then
            sort_by="${sort_by} {\$word_A = \$_.'${series_column_name}' -split ' '; \$value = ( \$word_A[0] + \$word_A[1] ) -replace '\D', ''; if (\$value -eq '') { 0 } else { [int]\$value } },"                
        fi
        sort_by="${sort_by} {[int]\$_.'Record ID number'}"
       
        (   echo "\$csv = import-csv -path '${filename}'"
            echo "\$csv = \$csv | Sort-Object ${sort_by}"
            echo "\$csv | export-csv '${filename_prefix}.sorted.csv'"
            echo "\$csv | convertto-json -compress | out-file '${filename_prefix}.compressed.json'"
            echo "\$csv | convertto-json           | out-file '${filename_prefix}.json'"
        ) | tee "${filename_prefix}.sort.ps1" | do_pwsh -x  
        [[ $? -gt 0 ]] && exit 5    #  This doesn't catch runtime errors...
        dos2unix "${filename_prefix}.compressed.json" 
        [[ $? -gt 0 ]] && exit 6
    fi
    (   
        eval run_ruby.sh formatter.inmagic.to.dictation_1.rb --box_only_line ${box_only_line} ${sort_detail} ${columns:+--columns }${columns} \
                                                             --output_file_prefix "${filename%.*}"  "${filename_prefix}.compressed.json" 
    )
) 2>> "${filename_prefix}.err"
[[ $? -gt 0 ]] && exit 7

exit 0

