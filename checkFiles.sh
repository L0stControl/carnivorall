#!/bin/bash
#=========================================================================
# Title           :checkFiles.sh
# Description     :Script to scan files looking for sensitive information.
# Authors         :L0stControl and BFlag
# Date            :2018/10/15
# Version         :0.3.9    
#=========================================================================

FILENAME=$1
PATTERNMATCH=$2
TMPDIR=$3
UNZIP=$(whereis unzip |awk '{print $2}')
GS=$(whereis gs |awk '{print $2}')
DSTFOLDER=$4
LOG=$5
MOUNTPOINT=$7
VERBOSE=$8
FILENAMEMSG=$(echo $6 |sed -e 's,'"$MOUNTPOINT\/"',,')
DEFAULTCOLOR="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
WHITE="\033[1;37m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
DEFAULTPST=$(cat /tmp/pstdefault)

function setPstDefault
{
    echo $1 > /tmp/pstdefault
}

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

function officeNew
{
    $UNZIP -q -o "$FILENAME" -d $TMPDIR > /dev/null 2>&1
    
    if [ $VERBOSE == "yes" ]; then

        if  RESULT=$(grep -i -R -A2 -B2 "$WORDPATTERN" $TMPDIR/*) ; then
            cpFiles "$GREEN [+]$WHITE - Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
            echo
            echo "$RESULT" | grep -i -A2 -B2 --color "$WORDPATTERN"
            echo
        fi
   
    else

        if ( grep -i -R "$WORDPATTERN" $TMPDIR/* ) > /dev/null 2>&1 ; then
            cpFiles "$GREEN [+]$WHITE - Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
        fi
   
    fi
}

function officeOld
{
    if [ $VERBOSE == "yes" ]; then

        if  RESULT=$(grep -i -a -A2 -B2 "$WORDPATTERN" "$FILENAME"); then
            cpFiles "$GREEN [+]$WHITE - Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
            echo
            echo -e "$RESULT" | grep -i -a -A2 -B2 --color "$WORDPATTERN"
            echo
        fi 

    else

        if ( grep -i -a "$WORDPATTERN" "$FILENAME" ) > /dev/null 2>&1 ; then
            cpFiles "$GREEN [+]$WHITE - Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
        fi 

    fi   
}

function defaultFiles
{
    DEFAULTPATTERN=$(echo "$PATTERNMATCH" |sed 's/ /|/g')

    if [ $VERBOSE == "yes" ]; then

        if  RESULT=$(grep -i -a -E -A2 -B2 "$DEFAULTPATTERN" "$FILENAME") ; then
            cpFiles "$GREEN [+]$WHITE - Looking for word [$RED$DEFAULTPATTERN$WHITE] on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
            echo
            echo -e "$RESULT" | grep -i -a -E -A2 -B2 --color "$DEFAULTPATTERN"
            echo
        fi

    else

        if ( grep -i -a -E "$DEFAULTPATTERN" "$FILENAME" ) > /dev/null 2>&1 ; then
            cpFiles "$GREEN [+]$WHITE - Looking for word [$RED$DEFAULTPATTERN$WHITE] on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
        fi

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
            cpFiles "$GREEN [+]$WHITE - Copying [$YELLOW PST file $WHITE] from  $FILENAMEMSG $GREEN[OK!]$DEFAULTCOLOR"
            exit
            ;;
        "s")
            exit
            ;;
        "a")
            setPstDefault 1
            cpFiles "$GREEN [+]$WHITE - Copying [$YELLOW PST file $WHITE] from  $FILENAMEMSG $GREEN[OK!]$DEFAULTCOLOR"
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
        
        cpFiles "$GREEN [+]$WHITE - Copying [$YELLOW PST file $WHITE] from  $FILENAMEMSG $GREEN[OK!]$DEFAULTCOLOR"
    
    elif [[ $DEFAULTPST -eq 2 ]]; then
    
        exit
        
    fi
}

shopt -s nocasematch

if [[ ${FILENAME: -4} =~ ".PST" ]]; then
    pstFiles
fi

if [[ ${FILENAME: -4} =~ ".KEY" ]] || [[ ${FILENAME: -4} =~ ".PCF" ]] || [[ ${FILENAME: -5} =~ ".OVPN" ]] ; then

    cpFiles "$GREEN [+]$WHITE - Possible [$RED VPN CONF / KEY $WHITE] $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"

fi

if ( file -n "$FILENAME"  | grep -i "ASCII" )  > /dev/null 2>&1 ; then

    defaultFiles

fi

for WORDPATTERN in $PATTERNMATCH
    do
        echo -en "$GREEN Checking file => $DEFAULTCOLOR$FILENAMEMSG \033[K\r"
        
        if [[ ${FILENAME: -5} =~ ".XLSX" ]] || [[ ${FILENAME: -5} =~ ".DOCX" ]] || [[ ${FILENAME: -5} =~ ".PPTX" ]] ; then
        
            officeNew

        elif [[ ${FILENAME: -4} =~ ".ODT" ]] || [[ ${FILENAME: -4} =~ ".ODS" ]] || [[ ${FILENAME: -4} =~ ".ODP" ]] ; then

            officeNew

        elif [[ ${FILENAME: -4} =~ ".DOC" ]] || [[ ${FILENAME: -4} =~ ".XLS" ]] || [[ ${FILENAME: -4} =~ ".PPT" ]] ; then

            officeOld

        elif [[ ${FILENAME: -4} =~ ".PDF" ]] || [[ $(file "$FILENAME"  | grep -i "PDF") ]]  > /dev/null 2>&1 ; then

            NUMCORES=$(nproc)
            
            if [ $VERBOSE == "yes" ]; then 
                
                if RESULT=$( timeout 60 $GS -dNumRenderingThreads="$NUMCORES" -dMaxPatternBitmap=2000000 -dNOPAUSE -sDEVICE=txtwrite -sOutputFile=- \
                    -dNOPROMPT -dQUIET -sstdout=%stderr -dBATCH "$FILENAME" 2>/dev/null | tr -s '[:blank:]' |grep -i -A2 -B2 "$WORDPATTERN") ; then
                
                    cpFiles "$GREEN [+]$WHITE - Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"
                    echo
                    echo -e "$RESULT" | grep -i -A2 -B2 --color "$WORDPATTERN"
                    echo

                fi

            else

                if ( timeout 60 $GS -dNumRenderingThreads="$NUMCORES" -dMaxPatternBitmap=2000000 -dNOPAUSE -sDEVICE=txtwrite -sOutputFile=- -dNOPROMPT -dQUIET \
                    -dBATCH "$FILENAME" | tr -s '[:blank:]' | grep -i "$WORDPATTERN" ) > /dev/null 2>&1 ; then
                
                    cpFiles "$GREEN [+]$WHITE - Looking for word [$RED$WORDPATTERN$WHITE] on file $FILENAMEMSG $GREEN[FOUND!]$DEFAULTCOLOR"

                fi
            fi
        fi
done

rm -rf $TMPDIR
