#!/bin/bash
#=========================================================================
#Title           :carnivoral.sh
#Description     :Look for sensitive information on the internal network.
#Authors         :L0stControl and BFlag
#Date            :2018/02/28
#Version         :0.5.8    
#Dependecies     :smbclient / ghostscript / zip / ruby / yara 
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

    Usage: ./carnivoral.sh [options]
    
        -n, --network <CIDR>                   192.168.0.0/24
        -l, --list <inputfilename>             List of hosts/networks
        -d, --domain <domain>                  Domain network
        -u, --username <guest>                 Domain username 
        -p, --password <guest>                 Domain password
        -o, --only <contents|filenames|yara>   Search ONLY by sensitve contents, filenames or yara rules
        -m, --match "user passw senha"         Strings to match inside files
        -y, --yara <juicy_files.txt>           Enable Yara search patterns
        -e, --emails <y|n>                     Download all \"*.pst\" files (Prompt by default) 
        -D, --delay <Number>                   Delay between requests  
        -h, --help                             Display options
        
        Ex1: ./carnivoral -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY  
        Ex2: ./carnivoral -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -o filenames
        Ex3: ./carnivoral -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -o yara -y juicy_files.txt 

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
KEY="$1"

case $KEY in
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
    -e|--emails)
    EMAILS="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--list)
    LIST="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--only)
    ONLY="$2"
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
LIST="${LIST:=notset}"
DOMAIN="${DOMAIN:=notset}"
USERNAME="${USERNAME:=notset}"
PASSWORD="${PASSWORD:=notset}"
YARAFILE="${YARAFILE:=notset}"
ONLY="${ONLY:=notset}"
DELAY="${DELAY:=0.2}"
EMAILS="${EMAILS:=0}"
PATTERNMATCH="${PATTERNMATCH:=senha passw}"
PIDCARNIVORAL=$$
MOUNTPOINT=~/.carnivoral/mnt
SHARESFILE=~/.carnivoral/shares.txt
FILESFOLDER=~/.carnivoral/files
SMB=$(whereis smbclient |awk '{print $2}')
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
    echo 1 > /dev/shm/holdcarnivoral # Using shared memory to avoid sync problems
    echo -e "$WHITE [-] Scanning $HOSTS $DEFAULTCOLOR"
    listShares $HOSTS $USERNAME $PASSWORD $DOMAIN
    for i in $SHARES; do
        PATHSMB=$(echo $i |awk -F"|" '{print $2}')
        READABLE=$(checkReadableShare $HOSTS $PATHSMB |tail -n1)
        if [ "$READABLE" == "True" ];then 
            printf "%-45s %-20s \n" " [+] smb://$HOSTS/$PATHSMB/" "| READ |"
            echo "$HOSTS,$PATHSMB" >> $SHARESFILE
        fi
    done
    echo 0 > /dev/shm/holdcarnivoral # Using shared memory to avoid sync problems
    SHARES=""
}

function generateTargets
{
    > $SHARESFILE # Clean targets file
    if [ "$LIST" != "notset" ]; then
        readarray -t IPS_FILE <<< "$(cat $LIST | while read LINE ; do generateRange.rb $LINE; done)"
        for HOSTS in "${IPS_FILE[@]}"
            do
                scanner $HOSTS &
                sleep $DELAY
            done 
    else
        readarray -t IPS <<< "$(generateRange.rb $NETWORK)"
        for HOSTS in "${IPS[@]}"
        do
            scanner $HOSTS &
            sleep $DELAY
        done
    fi   
}

function searchFilesByName
{
    HOSTSMB=$1
    PATHSMB=$2
    echo -e "$WHITE [+] Looking for suspicious filenames on smb://$HOSTSMB/$PATHSMB"
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
    echo -e "$WHITE [+] Looking for suspicious content files on smb://$HOSTSMB/$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB  
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp 
    fi
  
    find $MOUNTPOINT -type f -exec checkFiles.sh {} "$PATTERNMATCH" $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp $FILESFOLDER/$HOSTSMB\_$PATHSMB/ $LOG $MOUNTPOINT $HOSTSMB $PATHSMB \;

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
    echo -e "$GREEN [+]$WHITE Searching sensitive information with Yara smb://$HOSTSMB/$PATHSMB $DEFAULTCOLOR"
    echo
    $YARA -r $JUICE $MOUNTPOINT |tee -a $LOG
}

#------#
# main #
#------#

if [ "$NETWORK" == "notset" -a "$LIST" == "notset" ];then
    banner
    echo
    echo -e "$RED ERROR: $YELLOW You need to inform the network =( $DEFAULTCOLOR"
    echo
    exit
elif [ "$LIST" != "notset" -a ! -e "$LIST" ];then
    banner
    echo
    echo -e "$RED ERROR: $YELLOW File does not exist =( $DEFAULTCOLOR"
    echo
    exit
fi

if [ "$USERNAME" == "notset" -o $PASSWORD == "notset" ]; then
    OPTIONS="-N"
    OPTIONSMNT="-o user=,password="
else
    OPTIONS="-U $DOMAIN\\$USERNAME%$PASSWORD"
    OPTIONSMNT="-o user=$USERNAME,password=$PASSWORD,workgroup=$DOMAIN"
fi 

if [ "$EMAILS" == "y" ];then
    echo 1 > /tmp/pstdefault
    elif [ "$EMAILS" == "n" ];then
    echo 2 > /tmp/pstdefault
    else
    echo 0 > /tmp/pstdefault
fi

checkHomeFolders
generateTargets

while [ $(</dev/shm/holdcarnivoral) -eq 1 ]
do
    sleep 1
done

if [ -s "$SHARESFILE" ];then
    NUMBERLINESFILE=$(cat $SHARESFILE |wc -l)
    COUNT=1
    while :
    do
       echo
       echo -e "$YELLOW Choose your option $WHITE"
       echo 0 > /tmp/pstdefault
       echo
       cat $SHARESFILE |while read LINES
       do
           SMBLINE=$(echo $LINES |awk -F"," '{print "smb://"$1"/"$2}')
           echo -e " ( $COUNT ).... $SMBLINE"
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
           
               if [ $ONLY == "notset" -o $ONLY == "filenames" ];then
                   searchFilesByName $TARGETHOST $TARGETPATH
               fi

               if [ $ONLY == "notset" -o $ONLY == "contents" ];then
                   searchFilesByContent $TARGETHOST $TARGETPATH
               fi
               
               if [ $ONLY == "yara" -a $YARAFILE != "notset" ] ; then
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
           sleep 3
           ;;
       *)
           dateLog
           TARGETHOST=$(awk "NR==$OPT" $SHARESFILE|awk -F"," '{print $1}')
           TARGETPATH=$(awk "NR==$OPT" $SHARESFILE|awk -F"," '{print $2}')
           mountTarget $TARGETHOST $TARGETPATH
           
           if [ $ONLY == "notset" -o $ONLY == "filenames" ];then
               searchFilesByName $TARGETHOST $TARGETPATH
           fi
           
           if [ $ONLY == "notset" -o $ONLY == "contents" ];then
               searchFilesByContent $TARGETHOST $TARGETPATH           
           fi
           
           if [ $ONLY == "yara" -a $YARAFILE != "notset" ] ; then
               searchFilesWithYara $YARAFILE
           fi         
           umountTarget
           trap 2
           continue
           ;;
       esac
    done
fi
