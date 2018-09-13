#!/bin/bash
#====================================================================================
# Title           :checkRegex.sh
# Description     :Script to scan files looking for sensitive information using regex.
# Authors         :L0stControl and BFlag
# Date            :2018/09/05
# Version         :1.2.3    
#====================================================================================

FILENAME=$1
REGEX=$2
TMPDIR=$3
UNZIP=$(whereis unzip |awk '{print $2}')
GS=$(whereis gs |awk '{print $2}')
DSTFOLDER=$4
LOG=$5
MOUNTPOINT=$6
MOUNTPOINT2=$7
VERBOSE=$8
DEFAULTCOLOR="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
WHITE="\033[1;37m"

function logFiles
{
    MSG=$1
    echo -e "$MSG" >> $LOG
}

function cpFiles
{
    MSG=$1
    cp --backup=numbered "$FILENAME" "$DSTFOLDER"
    logFiles "$MSG"
    echo -e "$MSG" 
}

function officeNewRegex
{
    if [ $VERBOSE == "yes" ]; then
        $UNZIP -q -o "$FILENAME" -d $TMPDIR > /dev/null 2>&1
        if RESULT=$(egrep -i -R -A2 -B2 "$REGEX" $TMPDIR/*); then
            cpFiles "$GREEN [+]$WHITE - Looking for REGEX $RED$REGEX$WHITE on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
            echo
            echo "$RESULT" | egrep -i -A2 -B2 --color "$REGEX"
            echo
        fi
    else    
        $UNZIP -q -o "$FILENAME" -d $TMPDIR > /dev/null 2>&1
        if ( egrep -i -R --color "$REGEX" $TMPDIR/* ) > /dev/null 2>&1; then
            cpFiles "$GREEN [+]$WHITE - Looking for REGEX $RED$REGEX$WHITE on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
        fi
    fi
}

function officeOldRegex
{
    if [ $VERBOSE == "yes" ]; then
        if RESULT=$(egrep -i -a -A2 -B2 "$REGEX" "$FILENAME"); then
            cpFiles "$GREEN [+]$WHITE - Looking for REGEX $RED$REGEX$WHITE on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
            echo
            echo "$RESULT" | egrep -i -a -A2 -B2 --color "$REGEX"
            echo
        fi  
    else
        if ( egrep -i -a "$REGEX" "$FILENAME" ) > /dev/null 2>&1 ; then
            cpFiles "$GREEN [+]$WHITE - Looking for REGEX $RED$REGEX$WHITE on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
        fi  
    fi  
}

function defaultFiles
{
    if [ $VERBOSE == "yes" ]; then
        if RESULT=$(egrep -i -a -A2 -B2 "$REGEX" "$FILENAME"); then
            cpFiles "$GREEN [+]$WHITE - Looking for REGEX $RED$REGEX$WHITE on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
            echo
            echo "$RESULT" | egrep -i -a -A2 -B2 --color "$REGEX"
            echo
        fi
    else
        if ( egrep -i -a "\b$REGEX\b" "$FILENAME" ) > /dev/null 2>&1 ; then
            cpFiles "$GREEN [+]$WHITE - Looking for REGEX $RED$REGEX$WHITE on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
        fi
    fi
}

if ( echo "$MOUNTPOINT" |grep -i -s "smb://" ) > /dev/null 2>&1 ; then
    FILENAMEMSG=$MOUNTPOINT$(echo $FILENAME |sed -e 's,'"$MOUNTPOINT2"',,')
else
    FILENAMEMSG=$FILENAME
fi

shopt -s nocasematch

if ( file -n "$FILENAME" | grep -i "ASCII" ) > /dev/null 2>&1 ; then

    defaultFiles

fi

echo -en "$GREEN Checking file => $DEFAULTCOLOR$FILENAMEMSG \033[K\r"

if [[ ${FILENAME: -5} =~ ".XLSX" ]] || [[ ${FILENAME: -5} =~ ".DOCX" ]] || [[ ${FILENAME: -5} =~ ".PPTX" ]] ; then
    
    officeNewRegex

elif [[ ${FILENAME: -4} =~ ".ODT" ]] || [[ ${FILENAME: -4} =~ ".ODS" ]] || [[ ${FILENAME: -4} =~ ".ODP" ]] ; then

    officeNewRegex

elif [[ ${FILENAME: -4} =~ ".DOC" ]] || [[ ${FILENAME: -4} =~ ".XLS" ]] || [[ ${FILENAME: -4} =~ ".PPT" ]] ; then

    officeOldRegex

elif [[ ${FILENAME: -4} =~ ".PDF" ]]; then

    if [ $VERBOSE == "yes" ]; then
        if RESULT=$($GS -dNOPAUSE -sDEVICE=txtwrite -sOutputFile=- -dNOPROMPT -dQUIET -sstdout=%stderr \
            -dBATCH "$FILENAME" 2>/dev/null | egrep -i -A2 -B2 "$REGEX") ; then
            
            cpFiles "$GREEN [+]$WHITE - Looking for REGEX $RED$REGEX$WHITE on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
            echo
            echo -e "$RESULT" | egrep -i -A2 -B2 --color "$REGEX"
            echo
        fi
    else
        if ( $GS -dNOPAUSE -sDEVICE=txtwrite -sOutputFile=- -dNOPROMPT \
        -dQUIET -dBATCH "$FILENAME" | egrep -i "$REGEX" ) > /dev/null 2>&1 ; then
            
            cpFiles "$GREEN [+]$WHITE - Looking for REGEX $RED$REGEX$WHITE on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"

        fi
    fi
fi

rm -rf $TMPDIR

