#!/usr/bin/bash

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

run_ruby.sh formatter.txt.to.indent.dictation_1.rb "$2" 2>parsing.err | \
sort | \
run_ruby.sh formatter.indent.to.add_object.generic.rb --max_series=0 2>indent.err |\
run_ruby.sh spreadsheet.add_objects.to.csv.rb --ead $1 2> spreadsheet.err | tee ${2%.*}.csv >/dev/null

echo '========================================'
cat parsing.err
echo '========================================'
cat indent.err 
echo '========================================'
cat  spreadsheet.err

