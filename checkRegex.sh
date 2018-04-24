#!/bin/bash
#====================================================================================
# Title           :checkRegex.sh
# Description     :Script to scan files looking for sensitive information using regex.
# Authors         :L0stControl and BFlag
# Date            :2018/04/24
# Version         :1.1.2    
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
DEFAULTCOLOR="\033[0m"
BLACK="\033[0;30m"
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

function plainTextFilesRegex
{
    if ( egrep -i -a "\b$REGEX\b" "$FILENAME" ) > /dev/null 2>&1 ; then
        cpFiles "$GREEN [+]$WHITE - Looking for REGEX [$RED$REGEX$WHITE] on file $FILENAMEMSG...... $GREEN[FOUND!]$DEFAULTCOLOR"
    fi
}

function officeNewRegex
{
    $UNZIP -q -o "$FILENAME" -d $TMPDIR > /dev/null 2>&1
    if ( egrep -i -R --color "\b$REGEX\b" $TMPDIR/* ) > /dev/null 2>&1; then
        cpFiles "$GREEN [+]$WHITE - Looking for REGEX [$RED$REGEX$WHITE] on file $FILENAMEMSG...... $GREEN[FOUND!]$DEFAULTCOLOR"
    fi
}

function officeOldRegex
{
    if ( egrep -i -a "\b$REGEX\b" "$FILENAME" ) > /dev/null 2>&1 ; then
        cpFiles "$GREEN [+]$WHITE - Looking for REGEX [$RED$REGEX$WHITE] on file $FILENAMEMSG...... $GREEN[FOUND!]$DEFAULTCOLOR"
    fi    
}

function defaultFiles
{
    if ( egrep -i -a "\b$REGEX\b" "$FILENAME" ) > /dev/null 2>&1 ; then
        cpFiles "$GREEN [+]$WHITE - Looking for REGEX [$RED$REGEX$WHITE] on file $FILENAMEMSG...... $GREEN[FOUND!]$DEFAULTCOLOR"
    fi
}

if ( echo "$MOUNTPOINT" |grep -i -s "smb://" ) > /dev/null 2>&1 ; then
    FILENAMEMSG=$MOUNTPOINT$(echo $FILENAME |sed -e 's,'"$MOUNTPOINT2"',,')
else
    FILENAMEMSG=$FILENAME
fi

shopt -s nocasematch

if [[ ${FILENAME: -5} =~ ".XLSX" ]] || [[ ${FILENAME: -5} =~ ".DOCX" ]] || [[ ${FILENAME: -5} =~ ".PPTX" ]] ;then
    
    officeNewRegex

elif [[ ${FILENAME: -4} =~ ".DOC" ]] || [[ ${FILENAME: -4} =~ ".XLS" ]] || [[ ${FILENAME: -4} =~ ".PPT" ]] ;then

    officeOldRegex

elif [[ ${FILENAME: -4} =~ ".TXT" ]] || [[ ${FILENAME: -5} =~ ".CONF" ]] || [[ ${FILENAME: -4} =~ ".CSV" ]] ;then

    plainTextFilesRegex

elif [[ ${FILENAME: -4} =~ ".CNF" ]] || [[ ${FILENAME: -5} =~ ".XML" ]] || [[ ${FILENAME: -4} =~ ".CSV" ]] ;then

    plainTextFilesRegex

elif [[ ${FILENAME: -4} =~ ".PDF" ]];then 

    if ( $GS -dNOPAUSE -sDEVICE=txtwrite -sOutputFile=- -dNOPROMPT -dQUIET -dBATCH "$FILENAME" | egrep -i "\b$REGEX\b" ) > /dev/null 2>&1 ; then
            
        cpFiles "$GREEN [+]$WHITE - Looking for REGEX [$RED$REGEX$WHITE] on file $FILENAMEMSG...... $GREEN[FOUND!]$DEFAULTCOLOR"

    fi

elif ( file -n "$FILENAME" | grep -i "ASCII" ) > /dev/null 2>&1 ; then

    defaultFiles

fi

rm -rf $TMPDIR
