#!/bin/bash

# MDE - mysqldump Database Extract
# Extract specific database from mysqldump file
# Author: Vitor Martins - https://github.com/vmartins/mde
# Usage: mde.sh [OPTIONS]

ARGS_COUNT="$#"

# Gets the parameters
while [ "$1" != "" ]; do
    case $1 in
        -d )                shift
                            P_DATABASE=true
                            DB_SELECTED="$1"
                            ;;

        -i )                shift
                            INPUT_FILE=$1
                            ;;

        -o )                shift
                            P_OUTPUT=true
                            OUTPUT=$1
                            ;;

        -l | --list )       #shift
                            LIST_DATABASES=true
                            ;;

        -A | --databases )  #shift
                            ALL_DATABASES=true
                            ;;

        -? | --help )       #shift
                            P_HELP=true
                            ;;

        --version )         #shift
                            echo "$(basename $0) 0.9"
                            exit
                            ;;

        * )                 echo "$(basename $0): unknown option '$1'"
                            exit
                            ;;
    esac
    shift
done

if [[ "$ARGS_COUNT" -lt 1 || "$P_HELP" = true ]]; then
    head -7 $0 | tail -4 | awk -F'# ' '{print $2}'
    echo '  -?, --help         Display this help and exit'
    echo '  --version          Output version information and exit'
    echo '  -i <file>          Local MySql dump file'
    echo '  -l, --list         List the databases found in dump file'
    echo '  -A, --databases    Extract all databases from dump file to separate files'
    echo '  -d <db name>       Extract specific database from dump file'
    echo '  -o <output>        File (-d) or Directory (-A) to save the database extracted'
    exit
fi

# Validate parameters
if [[ -z "$INPUT_FILE" ]]; then #if empty
    echo "$(basename $0): option '-i' - mysql dump file not specified"
    exit
else
    if [[ ! -r "$INPUT_FILE" ]]; then #if empty
        echo "$(basename $0): option '-i' - mysql dump file not found"
        exit
    fi
fi

if [ "$P_DATABASE" = true ] ; then
    if [[ -z "$DB_SELECTED" ]]; then #if empty
        echo "$(basename $0): option '-d' - database name not specified"
        exit
    fi
fi


if [[ -z "$P_DATABASE" && -z "$ALL_DATABASES" ]]; then
    ALL_DATABASES=true
fi


if [ "$ALL_DATABASES" = true ] ; then
    if [ "$P_OUTPUT" = true ] ; then
        if [[ -z "$OUTPUT" ]]; then #if empty
            echo "$(basename $0): option '-o' - output dir not specified"
            exit
        fi

        if [[ ! -d "$OUTPUT" ]]; then
            echo "$(basename $0): option '-o' - the '$OUTPUT' is not a dir"
            exit
        fi

        if [[ ! -w "$OUTPUT" ]]; then
            echo "$(basename $0): option '-o' - the '$OUTPUT' is not a writable"
            exit
        fi
    fi
else
    if [ "$P_OUTPUT" = true ] ; then
        if [[ -z "$OUTPUT" ]]; then #if empty
            echo "$(basename $0): option '-o' - output file not specified"
            exit
        fi

        if [[ -a "$OUTPUT" ]]; then
            echo "$(basename $0): option '-o' - the '$OUTPUT' file already exists"
            exit
        fi
    fi
fi

# Searches the array for a given value and returns the corresponding key
array_search()    {
    local i=1 S=$1; shift
    while [ $S != $1 ]
    do    ((i++)); shift
        [ -z "$1" ] && { i=0; break; }
    done
    echo $i
}


# Extract one database from mysql dump file
extract() {
    local DB_SELECTED=$1

    INDEX_SELECTED=$(($(array_search $DB_SELECTED "${DBS_NAME[@]}")-1))

    LINE_SELECTED=${DBS_LINE[$INDEX_SELECTED]}
    LINE_NEXT=${DBS_LINE[$INDEX_SELECTED+1]}

    if [[ -z "$LINE_NEXT" ]]; then #last database
        LINE_NEXT=$(wc -l $INPUT_FILE | awk '{print $1}')
    fi

    #TODO: remove unnecessary strings from the end of file

    head -$(($LINE_NEXT-1)) $INPUT_FILE | tail -$(($LINE_NEXT-$LINE_SELECTED))
}

IFS=$'\n'
PATTERN='CREATE DATABASE .* `\(.*\)` .*;'
DBS_NAME=()
DBS_LINE=()
I=0;

for USE_LINE in $(grep -n "^$PATTERN" $INPUT_FILE); do
    DB_LINE=$(echo $USE_LINE | awk -F ':' '{ print $1 }')
    DB_NAME=$(echo $USE_LINE | awk -F ':' '{ print $2 }' | sed "s/$PATTERN/\1/")

    DBS_LINE[$I]=$DB_LINE
    DBS_NAME[$I]=$DB_NAME

    let "I++"
done

# list all databases
if [ "$LIST_DATABASES" = true ] ; then
    for i in "${DBS_NAME[@]}"
    do
       :
       echo $i
    done
    exit
fi

# extract all databases
if [ "$ALL_DATABASES" = true ] ; then
    if [[ -z "$OUTPUT" ]]; then #if empty
        OUTPUT_DIR=''
    else
        OUTPUT_DIR="${OUTPUT%/}/"
    fi

    for i in "${DBS_NAME[@]}"
    do
        :
        OUTPUT_FILENAME="$OUTPUT_DIR$i-$(basename $INPUT_FILE)"
        echo -n $i;
        extract $i > $OUTPUT_FILENAME
        echo " > $OUTPUT_FILENAME"
    done
    exit;
fi

# extract specific database
I=$(array_search $DB_SELECTED "${DBS_NAME[@]}")

if [ $I -eq 0 ]
then
    echo "$(basename $0): Database '$DB_SELECTED' not found in $INPUT_FILE"
    exit
fi

if [ "$P_OUTPUT" = true ] ; then
    extract $DB_SELECTED > $OUTPUT
else
    extract $DB_SELECTED
fi


