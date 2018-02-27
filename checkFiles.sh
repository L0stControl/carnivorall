#!/bin/bash
#=========================================================================
#Title           :checkFiles.sh
#Description     :Script to scan files looking for sensitive information.
#Authors         :L0stControl and BFlag
#Date            :2018/02/27
#Version         :0.1.3    
#=========================================================================

FILENAME=$1
PATTERNMATCH=$2
TMPDIR=$3
UNZIP=$(whereis unzip |awk '{print $2}')
PDFTOTEXT=$(whereis pdftotext |awk '{print $2}')
DSTFOLDER=$4
LOG=$5
MOUNTPOINT=$6
HOSTSMB=$7
PATHSMB=$8
FILENAMEMSG=$(echo $FILENAME |sed "s/^.\{,${#MOUNTPOINT}\}/$HOSTSMB\/$PATHSMB/")
DEFAULTCOLOR="\033[0m"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
WHITE="\033[1;37m"
MAGENTA="\033[1;35m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
DEFAULTPST=$(cat /tmp/pstdefault)

function setPstDefault
{
    echo $1 > /tmp/pstdefault
}

function logFiles
{
    echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
}

function cpFiles
{
    
    echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file smb://$FILENAMEMSG...... $GREEN[FOUND!]$DEFAULTCOLOR"
    cp --backup=numbered "$FILENAME" "$DSTFOLDER" 
}

function officeNew
{
    $UNZIP -q -o "$FILENAME" -d $TMPDIR > /dev/null 2>&1
    if grep -i -R "$WORDPATTERN" $TMPDIR/* > /dev/null 2>&1 ; then
        cpFiles
        logFiles
    fi
}

function officeOld
{
    if grep -i -a "$WORDPATTERN" "$FILENAME" > /dev/null 2>&1 ; then
        cpFiles
        logFiles
    fi    
}

function plainTextFiles
{
    if grep -i -a "$WORDPATTERN" "$FILENAME" > /dev/null 2>&1 ; then
        cpFiles
        logFiles
    fi
}

function pstFiles
{
    if [[ $DEFAULTPST -eq 0 ]]; then
        echo -e "$RED --------------------------------- "
        echo -e "$YELLOW  E-mails (\".PST\") files FOUND!! "
        echo -e "$RED --------------------------------- $WHITE"
        echo -e " What do you wanna do? $WHITE"
        echo -e "$DEFAULTCOLOR ( d ).... Download the current file"
        echo -e "$DEFAULTCOLOR ( s ).... Skip this file"
        echo -e "$DEFAULTCOLOR ( a ).... Download all \".PST\" files (Are you sure?)"
        echo -e "$DEFAULTCOLOR ( n ).... Skip all \".PST\" files"
        echo
        echo -en " Option ......................: "
        read OPT2
        echo -e "$DEFAULTCOLOR"
        
        case $OPT2 in
        "d")
            cpFiles
            logFiles
            exit
            ;;
        "s")
            exit
            ;;
        "a")
            setPstDefault 1
            cpFiles
            logFiles       
            ;;
        "n")
            setPstDefault 2
            exit
            ;;
          *)
            exit
            ;;
        esac 
    elif [[ $DEFAULTPST -eq 1 ]]; then
        
        cpFiles
        logFiles
    
    elif [[ $DEFAULTPST -eq 2 ]]; then
    
        exit
        
    fi
}

shopt -s nocasematch

for WORDPATTERN in $PATTERNMATCH
    do
        if [[ ${FILENAME: -5} =~ ".XLSX" ]] || [[ ${FILENAME: -5} =~ ".DOCX" ]] || [[ ${FILENAME: -5} =~ ".PPTX" ]] ;then
        
            officeNew
        
        elif [[ ${FILENAME: -4} =~ ".DOC" ]] || [[ ${FILENAME: -4} =~ ".XLS" ]] || [[ ${FILENAME: -4} =~ ".PPT" ]] ;then

            officeOld

        elif [[ ${FILENAME: -4} =~ ".TXT" ]] || [[ ${FILENAME: -5} =~ ".CONF" ]] || [[ ${FILENAME: -4} =~ ".CSV" ]] ;then

            plainTextFiles
        
        elif [[ ${FILENAME: -4} =~ ".CNF" ]] || [[ ${FILENAME: -5} =~ ".XML" ]] || [[ ${FILENAME: -4} =~ ".CSV" ]] ;then

            plainTextFiles

        elif [[ ${FILENAME: -4} =~ ".PDF" ]];then

            if $PDFTOTEXT "$FILENAME" - | grep -i -a "$WORDPATTERN" > /dev/null 2>&1 ; then
                echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file smb://$FILENAMEMSG...... $GREEN[FOUND!]$DEFAULTCOLOR"
                cp --backup=numbered "$FILENAME" "$DSTFOLDER"
                echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
            fi
            
        fi
done

if [[ ${FILENAME: -4} =~ ".PST" ]]; then
    pstFiles
fi

rm -rf $TMPDIR
