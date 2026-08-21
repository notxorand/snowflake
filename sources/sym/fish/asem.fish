set -l input_file ""
set -l output_file ""

if test "$argv[1]" = ""
    echo "Compile assembly to binaries via GCC."
    echo "asem [options]"
    echo ""
    echo "Options:"
    echo "  -i - input file"
    echo "  -o - output file"
    echo ""
    echo "Shorthand: asem [file_name]"
    echo "  Note: should be a file with .s"
    exit 0
else
    set -l arg_index 2
    for arg in $argv
        if test "$arg" = "-i"
            set input_file "$argv[$arg_index]"
            if test "$argv[4]" = ""
                echo "Incomplete fields."
                exit 1
            end
        else if test "$arg" = "-o"
            set output_file "$argv[$arg_index]"
            if test "$argv[4]" = ""
                echo "Incomplete fields."
                exit 1
            end
        else if test "$input_file" = "" || test "$output_file" = "-o"
            set input_file "$argv[1]".s
            set output_file "$argv[1]"
        end

        set arg_index (math $arg_index + 1)
    end
    if test "$input_file" = ""
        echo "Missing input file. Set with field: -i."
        exit 1
    else if test "$output_file" = ""
        echo "Missing output file. Set with field: -o."
        exit 1
    end
end


as "$input_file" -o "$output_file".o
gcc -o "$output_file" "$output_file".o -nostdlib -static
