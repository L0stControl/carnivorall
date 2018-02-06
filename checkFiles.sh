#!/bin/bash

FILENAME=$1
PATTERNMATCH=$2
TMPDIR=$3
UNZIP=$(whereis unzip |awk '{print $2}')
PDFTOTEXT=$(whereis pdftotext |awk '{print $2}')
DSTFOLDER=$4
LOG=$5
DEFAULTCOLOR="\033[0m"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
WHITE="\033[1;37m"
MAGENTA="\033[1;35m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"

for WORDPATTERN in $PATTERNMATCH
    do
        if [ ${FILENAME: -5} == ".xlsx" ];then

            $UNZIP -q -o "$FILENAME" -d $TMPDIR
            if grep --color -i -R "$WORDPATTERN" $TMPDIR/* 2>&1 > /dev/null ; then
                echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAME...... $GREEN[FOUND!]$DEFAULTCOLOR"
                cp --backup=numbered "$FILENAME" "$DSTFOLDER"
                echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
            fi

        elif [ ${FILENAME: -5} == ".docx" ];then
    
            $UNZIP -q -o "$FILENAME" -d $TMPDIR
            if grep --color -i -R "$WORDPATTERN" $TMPDIR/* 2>&1 > /dev/null ; then
                echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAME...... $GREEN[FOUND!]$DEFAULTCOLOR"
                cp --backup=numbered "$FILENAME" $DSTFOLDER
                echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
            fi

        elif [ ${FILENAME: -5} == ".pptx" ];then

            $UNZIP -q -o "$FILENAME" -d $TMPDIR
            if grep --color -i -R "$WORDPATTERN" $TMPDIR/* 2>&1 > /dev/null ; then
                echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAME...... $GREEN[FOUND!]$DEFAULTCOLOR"
                cp --backup=numbered "$FILENAME" "$DSTFOLDER"
                echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
            fi

        elif [ ${FILENAME: -4} == ".txt" ];then

            if grep --color -i -a "$WORDPATTERN" "$FILENAME" 2>&1 > /dev/null ; then
                echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAME...... $GREEN[FOUND!]$DEFAULTCOLOR"
                cp --backup=numbered "$FILENAME" "$DSTFOLDER"
                echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
            fi

        elif [ ${FILENAME: -4} == ".doc" ];then

            if grep --color -i -a "$WORDPATTERN" "$FILENAME" 2>&1 > /dev/null ; then
                echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAME...... $GREEN[FOUND!]$DEFAULTCOLOR"
                cp --backup=numbered "$FILENAME" $DSTFOLDER
                echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
            fi
    
        elif [ ${FILENAME: -4} == ".csv" ];then

            if grep --color -i -a "$WORDPATTERN" "$FILENAME" 2>&1 > /dev/null ; then
                echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAME...... $GREEN[FOUND!]$DEFAULTCOLOR"
                cp --backup=numbered "$FILENAME" $DSTFOLDER
                echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
            fi

        elif [ ${FILENAME: -4} == ".zip" ];then
                 
                echo -e "$YELLOW [+] $WHITE ZIP file $FILENAME...... $GREEN[FOUND!]$DEFAULTCOLOR"
                echo -e "$YELLOW The file $FILENAME was not copied $DEFAULTCOLOR"   

        elif [ ${FILENAME: -4} == ".pdf" ];then

            if $PDFTOTEXT "$FILENAME" - | grep --color -i -a "$WORDPATTERN" 2>&1 > /dev/null ; then
                echo -e "$GREEN [+] $WHITE Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAME...... $GREEN[FOUND!]$DEFAULTCOLOR"
                cp --backup=numbered "$FILENAME" $DSTFOLDER
                echo "Pattern $WORDPATTERN found on => $DSTFOLDER$(echo $FILENAME | awk -F"/" '{print $NF}')" >> $LOG
            fi
            
        fi
done
rm -rf $TMPDIR
