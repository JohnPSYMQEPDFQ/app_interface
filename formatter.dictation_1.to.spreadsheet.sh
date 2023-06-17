#!/usr/bin/bash

myself_name=$(basename ${0%.*})
if [[ -z "$2" ]] 
then
    echo "Param 1 is the ead_id"
    echo "Param 2 is the file"
    exit 1
fi
if [[ ! -a "$2" ]] 
then
    echo "Can't find file: '$2'"
    exit 2
fi

run_ruby.sh formatter.txt.to.indent.dictation_1.rb "$2" 2>${myself_name}.parsing.err | tee ${myself_name}.parsing.txt | \
sort -f | \
run_ruby.sh formatter.indent.to.add_objects.generic.rb --max_series=0 2>${myself_name}.indent.err | tee ${2%.*}.add_objects.txt |\
run_ruby.sh spreadsheet.add_objects.to.csv.rb --ead $1 2> ${myself_name}.spreadsheet.err | tee ${2%.*}.csv >/dev/null

echo '========================================'
cat ${myself_name}.parsing.err
echo '========================================'
cat ${myself_name}.indent.err 
echo '========================================'
cat ${myself_name}.spreadsheet.err

