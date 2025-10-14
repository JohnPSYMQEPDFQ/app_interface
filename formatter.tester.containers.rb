#!run_ruby.sh

require 'class.ArchivesSpace.rb'

if ( ARGV.length > 0 ) then 
    input_string = ARGV.join(" ")  
elsif ( $stdin.stat.pipe? ) then
    SE.puts "No test string found on command line, input from pipe..."
    input_string = ARGF.each_line.to_a.join( ' ' ).chomp
else
    SE.puts "No ARGV"
    exit
end

m_O = input_string.match( K.container_and_child_types_RE )
SE.q {['m_O']}

