#!/bin/bash

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
        -D, --delay <Number>             Delay between requests  
        -h, --help                       Display options
        
EOF
}

#-----------#
# Constants #
#-----------#

SMB=$(whereis smbclient |awk '{print $2}')
NMB=$(whereis nmblookup |awk '{print $2}')
MNT=$(whereis mount |awk '{print $2}')
UMNT=$(whereis umount |awk '{print $2}')
YARA=$(whereis yara |awk '{print $2}')
LOG="log"
FILESFOLDER="./files/"
PATTERNMATCH="*senha* *passw* *username* *usuario* *users*"
SHARESFILE="./shares.txt"
SHARES=""
DEFAULTCOLOR="\033[0m"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
WHITE="\033[1;37m"
MAGENTA="\033[1;35m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"

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
    -m|--mountpoint)
    MOUNTPOINT="$2"
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

NETWORK="${NETWORK:=notset}"
DOMAIN="${DOMAIN:=notset}"
USERNAME="${USERNAME:=notset}"
PASSWORD="${PASSWORD:=notset}"
DELAY="${DELAY:=0.3}"
MOUNTPOINT="${MOUNTPOINT:=./mnt}"

if [ "$USERNAME" == "notset" -o $PASSWORD == "notset" ]; then
    OPTIONS="-N"
    OPTIONSMNT="-o user=,password="
else
    OPTIONS="-U $DOMAIN\\\\$USERNAME\%$PASSWORD"
    OPTIONSMNT="-o user=$USERNAME,password=$PASSWORD,workgroup=$DOMAIN"
fi 

#-----------#
# Functions #
#-----------#

function listShares 
{
    HOSTSMB=$1
    USERNAME=$2
    PASSWORD=$3
    DOMAIN=$4

    if [ "$DOMAIN" == "notset" ]; then
        DOMAIN=$($NMB -A $HOSTSMB |awk '{print $1}' |sed -n 2p)
        if [ $DOMAIN == "notset" ]; then
            DOMAIN="WORKGROUP"
        fi
    fi 

    exec 2> /dev/null # GoHorse to clean the outputs
    SHARES=$($SMB -g -L $HOSTSMB $OPTIONS |grep -i "Disk" |grep -v "print")
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
            #echo "smb:\\\\$HOSTS\\$PATHSMB\\ .....: READ!" 
            printf "%-45s %-20s \n" " [+] smb:\\\\$HOSTS\\$PATHSMB\\" "| READ |"
            echo "$HOSTS,$PATHSMB" >> $SHARESFILE
        fi
    done
    SHARES=""
}

function generateTargets
{
    truncate -s 0 $SHARESFILE #Clean targets file

    ./generateRange.rb $NETWORK |while read HOSTS 
    do
        scanner $HOSTS &
        sleep $DELAY
    done
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
    trap '' 2 # Disable Ctrl-C  
fi    
}

function searchFilesByName
{
    HOSTSMB=$1
    PATHSMB=$2
    echo -e "$WHITE [+] Looking for suspicious name files on smb:\\\\\\$HOSTSMB\\\\$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    echo >> $LOG
    echo "----------------------------" >> $LOG
    date >> $LOG
    echo "----------------------------" >> $LOG
    echo >> $LOG
    for p in $PATTERNMATCH
    do
        find $MOUNTPOINT -printf '%p\n' -iname "$p" -exec cp -n --parents {} "$FILESFOLDER/" \; | sed "s/^.\{,${#MOUNTPOINT}\}/[+] - $HOSTSMB\/$PATHSMB/" | tail -n +2 |tee -a $LOG
    done
    if [ -d $FILESFOLDER/$MOUNTPOINT ];then
        mv $FILESFOLDER/$MOUNTPOINT $FILESFOLDER/$HOSTSMB\_$PATHSMB
    fi
    echo
}

function umountTarget
{
    $UMNT -l -f $MOUNTPOINT
    trap 2 # Enable Ctrl-C
}

function searchFilesByContent
{
    echo -e "$WHITE [+] Searching sensitive information on smb:\\\\\\$HOSTSMB\\\\$PATHSMB"
    echo
    $YARA -r $MOUNTPOINT |tee -a $LOG
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

generateTargets

if [ -s "$SHARESFILE" ];then
    NUMBERLINESFILE=$(cat $SHARESFILE |wc -l)
    COUNT=1
    while :
    do
       clear
       echo
       echo -e "$RED Choose your option $WHITE"
       
       echo
       cat $SHARESFILE |while read LINES
       do
           echo -e " ( $COUNT ).... $LINES"
           COUNT=$(($COUNT + 1))
       done
       echo -e "$DEFAULTCOLOR ( a ).... Scan all targets"
       echo -e "$DEFAULTCOLOR ( r ).... Rescan target(s)"       
       echo -e " ( q ).... Quit" 
       echo
       echo -en " Option ......................: "
       read OPT
       echo -e "$DEFAULTCOLOR"
       
       case $OPT in
       "a")
           for (( i=1; i <= $NUMBERLINESFILE; i++)) 
           do
               TARGETHOST=$(awk "NR==$i" $SHARESFILE|awk -F"," '{print $1}')
               TARGETPATH=$(awk "NR==$i" $SHARESFILE|awk -F"," '{print $2}')
               mountTarget $TARGETHOST $TARGETPATH
               searchFilesByName $TARGETHOST $TARGETPATH
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
           TARGETHOST=$(awk "NR==$OPT" $SHARESFILE|awk -F"," '{print $1}')
           TARGETPATH=$(awk "NR==$OPT" $SHARESFILE|awk -F"," '{print $2}')
           mountTarget $TARGETHOST $TARGETPATH
           searchFilesByName $TARGETHOST $TARGETPATH
           umountTarget
           trap 2
           continue
           ;;
       esac
    done
fi