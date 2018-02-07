#!/bin/bash
#=========================================================================
#Title           :carnivoral.sh
#Description     :Look for sensitive information on the internal network.
#Authors		 :L0stControl and BFlag
#Date            :2018/02/04
#Version         :0.5.1    
#Dependecies     :smbclient / xpdf-utils / zip / ruby / yara 
#=========================================================================

SCRIPTHOME=$(readlink -f "$0" | rev | cut -d '/' -f 2- | rev)
export PATH=$PATH:$SCRIPTHOME

function banner {
    cat << EOF
    
    ========================================================================================
     
     ▄████▄   ▄▄▄       ██▀███   ███▄    █  ██▓ ██▒   █▓ ▒█████   ██▀███   ▄▄▄       ██▓      
    ▒██▀ ▀█  ▒████▄    ▓██ ▒ ██▒ ██ ▀█   █ ▓██▒▓██░   █▒▒██▒  ██▒▓██ ▒ ██▒▒████▄    ▓██▒      
    ▒▓█    ▄ ▒██  ▀█▄  ▓██ ░▄█ ▒▓██  ▀█ ██▒▒██▒ ▓██  █▒░▒██░  ██▒▓██ ░▄█ ▒▒██  ▀█▄  ▒██░      
    ▒▓▓▄ ▄██▒░██▄▄▄▄██ ▒██▀▀█▄  ▓██▒  ▐▌██▒░██░  ▒██ █░░▒██   ██░▒██▀▀█▄  ░██▄▄▄▄██ ▒██░      
    ▒ ▓███▀ ░ ▓█   ▓██▒░██▓ ▒██▒▒██░   ▓██░░██░   ▒▀█░  ░ ████▓▒░░██▓ ▒██▒ ▓█   ▓██▒░██████▒  
    ░ ░▒ ▒  ░ ▒▒   ▓▒█░░ ▒▓ ░▒▓░░ ▒░   ▒ ▒ ░▓     ░ ▐░  ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░ ▒░▓  ░  
      ░  ▒     ▒   ▒▒ ░  ░▒ ░ ▒░░ ░░   ░ ▒░ ▒ ░   ░ ░░    ░ ▒ ▒░   ░▒ ░ ▒░  ▒   ▒▒ ░░ ░ ▒  ░  
    ░          ░   ▒     ░░   ░    ░   ░ ░  ▒ ░     ░░  ░ ░ ░ ▒    ░░   ░   ░   ▒     ░ ░     
    ░ ░            ░  ░   ░              ░  ░        ░      ░ ░     ░           ░  ░    ░  ░  
    ░                                                                                       
      
    ========================================================================================             
                --=={ Looking for sensitive information on local network }==--                                  

    Usage: ./carnivoral.rb [options]
    
        -n, --network <CIDR>             192.168.0.0/24
        -d, --domain <domain>            Domain network
        -u, --username <guest>           Domain Username 
        -p, --password <guest>           Domain Username
        -m, --match "user passw senha"   Strings to match inside files
        -y, --yara <juicy_files.txt>     Enable Yara search patterns
        -D, --delay <Number>             Delay between requests  
        -h, --help                       Display options
        
EOF
}

#----------------#
# Options parser #
#----------------#

if [ "$1" == "-h" -o "$1" == "--help" -o -z "$1" ]; then 
    banner
    exit
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--network)
    NETWORK="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--domain)
    DOMAIN="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--username)
    USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--password)
    PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    -D|--delay)
    DELAY="$2"
    shift # past argument
    shift # past value
    ;;
    -m|--match)
    PATTERNMATCH="$2"
    shift # past argument
    shift # past value
    ;;
    -y|--yara)
    YARAFILE="$2"
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#-------------------------#
# Constants and variables #
#-------------------------#

NETWORK="${NETWORK:=notset}"
DOMAIN="${DOMAIN:=notset}"
USERNAME="${USERNAME:=notset}"
PASSWORD="${PASSWORD:=notset}"
YARAFILE="${YARAFILE:=notset}"
DELAY="${DELAY:=0.2}"
PATTERNMATCH="${PATTERNMATCH:=senha passw}"
PIDCARNIVORAL=$$
MOUNTPOINT=~/.carnivoral/mnt
SHARESFILE=~/.carnivoral/shares.txt
FILESFOLDER=~/.carnivoral/files
SMB=$(whereis smbclient |awk '{print $2}')
NMB=$(whereis nmblookup |awk '{print $2}')
MNT=$(whereis mount |awk '{print $2}')
UMNT=$(whereis umount |awk '{print $2}')
YARA=$(whereis yara |awk '{print $2}')
LOG=~/.carnivoral/log
SHARES=""
DEFAULTCOLOR="\033[0m"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
WHITE="\033[1;37m"
MAGENTA="\033[1;35m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
EXITCTRL=0

if [ "$USERNAME" == "notset" -o $PASSWORD == "notset" ]; then
    OPTIONS="-N"
    OPTIONSMNT="-o user=,password="
else
    OPTIONS="-U $DOMAIN\\$USERNAME%$PASSWORD"
    OPTIONSMNT="-o user=$USERNAME,password=$PASSWORD,workgroup=$DOMAIN"
fi 

#-----------#
# Functions #
#-----------#

function checkHomeFolders
{
    if [ ! -d ~/.carnivoral ]; then
        mkdir -p ~/.carnivoral 
        mkdir -p $FILESFOLDER 
        mkdir -p $MOUNTPOINT 
        touch $SHARESFILE 
        touch $LOG 
    fi    
}

function dateLog
{ 
    MSG=$1
    echo >> $LOG
    echo "----------------------------" >> $LOG
    date >> $LOG
    echo "----------------------------" >> $LOG
    echo "$MSG" >> $LOG 
}

function listShares 
{
    HOSTSMB=$1
    USERNAME=$2
    PASSWORD=$3
    DOMAIN=$4

    if [ "$DOMAIN" == "notset" ]; then
        if $NMB -A $HOSTSMB 2>&1 > /dev/null; then
            DOMAIN=$($NMB -A $HOSTSMB |awk '{print $1}' |sed -n 2p)
        else
            DOMAIN="WORKGROUP"
        fi
    fi 

    exec 2> /dev/null # GoHorse to clean the outputs
    SHARES=$($SMB -g -L \\\\$HOSTSMB $OPTIONS |grep -i "Disk" |grep -v "print")
    SHARES=$(echo $SHARES |grep -i "Disk")
    exec 1> /dev/tty # GoHorse to clean the outputs 
}

function checkReadableShare 
{
    HOSTSMB=$1
    PATHSMB=$2
    if $SMB \\\\$HOSTSMB\\$PATHSMB $OPTIONS -c ls 2>&1 > /dev/null ; then
        echo "True"
    else
        echo "False"
    fi
}

function scanner
{
    HOSTS=$1
    echo -e "$WHITE [-] Scanning $HOSTS $DEFAULTCOLOR"
    listShares $HOSTS $USERNAME $PASSWORD $DOMAIN
    for i in $SHARES; do
        PATHSMB=$(echo $i |awk -F"|" '{print $2}')
        READABLE=$(checkReadableShare $HOSTS $PATHSMB |tail -n1)
        if [ "$READABLE" == "True" ];then 
            printf "%-45s %-20s \n" " [+] smb:\\\\$HOSTS\\$PATHSMB\\" "| READ |"
            echo "$HOSTS,$PATHSMB" >> $SHARESFILE
        fi
    done
    SHARES=""
}

function generateTargets
{
    > $SHARESFILE #Clean targets file

    generateRange.rb $NETWORK |while read HOSTS 
    do
        scanner $HOSTS &
        sleep $DELAY
    done
sleep 7
}

function searchFilesByName
{
    HOSTSMB=$1
    PATHSMB=$2
    echo -e "$WHITE [+] Looking for suspicious filenames on smb:\\\\\\$HOSTSMB\\\\$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB 2>&1 > /dev/null
    fi
 
    for p in $PATTERNMATCH
    do
        find $MOUNTPOINT \( -iname "*"$p"*" ! -iname "*.zip" \) -printf '%p\n' -type f -exec cp --backup=numbered {} $FILESFOLDER/$HOSTSMB\_$PATHSMB \; | sed "s/^.\{,${#MOUNTPOINT}\}/ [+] - $HOSTSMB\/$PATHSMB/" | tail -n +2 |tee -a $LOG
    done
    
    if [ ! "$(ls -A $FILESFOLDER/$HOSTSMB\_$PATHSMB/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$HOSTSMB\_$PATHSMB/
    fi
    echo
}

function searchFilesByContent
{
    HOSTSMB=$1
    PATHSMB=$2
    echo -e "$WHITE [+] Looking for suspicious content files on smb:\\\\\\$HOSTSMB\\\\$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB  
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp 
    fi

    find $MOUNTPOINT -type f -exec checkFiles.sh {} "$PATTERNMATCH" $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp $FILESFOLDER/$HOSTSMB\_$PATHSMB/ $LOG \;

    
    if [ ! "$(ls -A $FILESFOLDER/$HOSTSMB\_$PATHSMB/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$HOSTSMB\_$PATHSMB/
    fi
    echo
   
}

function umountTarget
{
    $UMNT -l -f $MOUNTPOINT
    trap 2 # Enable Ctrl-C
}

function exitScan 
{
    echo -e "$RED............Scan stopped! keep hacking =)$DEFAULTCOLOR"
    umountTarget
    kill -9 $PIDCARNIVORAL     
}

function mountTarget
{
HOSTSMB=$1
PATHSMB=$2
if [ $(id -u) -ne 0 ];then
    echo
    echo -e "$RED  You must be root to use this options =( $DEFAULTCOLOR"
    echo
    exit
else
    $MNT -t cifs //$HOSTSMB/$PATHSMB $MOUNTPOINT $OPTIONSMNT
    trap exitScan 2 # Disable Ctrl-C   
fi    
}

function searchFilesWithYara
{
    JUICE=$1
    echo -e "$GREEN [+]$WHITE Searching sensitive information with Yara smb:\\\\\\$HOSTSMB\\\\$PATHSMB $DEFAULTCOLOR"
    echo
    $YARA -r $JUICE $MOUNTPOINT |tee -a $LOG
}

#------#
# main #
#------#

if [ "$NETWORK" == "notset" ];then
    echo
    echo -e "$RED  You need to inform the network =( $DEFAULTCOLOR"
    banner
    exit
fi

checkHomeFolders
generateTargets


if [ -s "$SHARESFILE" ];then
    NUMBERLINESFILE=$(cat $SHARESFILE |wc -l)
    COUNT=1
    while :
    do
       echo
       echo -e "$RED Choose your option $WHITE"
       
       echo
       cat $SHARESFILE |while read LINES
       do
           echo -e " ( $COUNT ).... $LINES"
           COUNT=$(($COUNT + 1))
       done
       echo -e "$DEFAULTCOLOR ( a ).... Look for files in all targets"
       echo -e "$DEFAULTCOLOR ( r ).... Rescan target(s)"       
       echo -e " ( q ).... Quit" 
       echo
       echo -en " Option ......................: "
       read OPT
       echo -e "$DEFAULTCOLOR"
       
       case $OPT in
       "a")
           dateLog
           for (( T=1; T <= $NUMBERLINESFILE; T++)) 
           do
               TARGETHOST=$(awk "NR==$T" $SHARESFILE|awk -F"," '{print $1}')
               TARGETPATH=$(awk "NR==$T" $SHARESFILE|awk -F"," '{print $2}')
               mountTarget $TARGETHOST $TARGETPATH
               searchFilesByName $TARGETHOST $TARGETPATH
               searchFilesByContent $TARGETHOST $TARGETPATH
               if [ $YARA != "notset" ]; then
                   searchFilesWithYara $YARAFILE
               fi 
               umountTarget
           done
           continue
           ;;
       "q")
           exit
           ;;
       "r")
           generateTargets
           ;;
       *)
           dateLog
           TARGETHOST=$(awk "NR==$OPT" $SHARESFILE|awk -F"," '{print $1}')
           TARGETPATH=$(awk "NR==$OPT" $SHARESFILE|awk -F"," '{print $2}')
           mountTarget $TARGETHOST $TARGETPATH
           searchFilesByName $TARGETHOST $TARGETPATH
           searchFilesByContent $TARGETHOST $TARGETPATH
           if [ $YARAFILE != "notset" ]; then
               searchFilesWithYara $YARAFILE
           fi 
           umountTarget
           trap 2
           continue
           ;;
       esac
    done
fi
