```                                                                                     
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
 
 ```
                                          CARNIVORALL
                --=={ Looking for sensitive information on local network }==-- 
                
# Authors: L0stControl and BFlag

# Intro

Scan files looking for sensitive information on SMB shares, local folders and public websites. 

# Usage

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
        -g, --google <max items>                    Search files on the website using Google 
                                                    (Obs: Set to "0" to search in local files)
        -w, --website "domain.com"                  Website used at *-g/--google* feature
        -v, --verbose no                            Display all matches at run time (default yes)
        
        Ex1: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY  
        Ex2: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -o filenames
        Ex3: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -o yara -y juicy_files.txt

        -={ Command & Control Module }=-

        -lH, --lhost 192.168.0.1                     Local ip to receive zombies responses
        -lP, --lport 80                              Local port to listen
        -pP, --pspayload <payload.ps1>                 Powershell payload file

        Ex4: ./carnivorall -n 192.168.0.0/24 -u Admin -p Admin -d COMPANY -lH 192.168.1.2 
            -pP ./payload.ps1 -lP 80 
        
        Ex5: ./carnivorall -lH 192.168.1.2 -lP 80 # Listen mode. 

# Requirements:

- cifs-utils 
- GhostScript
- zip
- ruby (gems -> nokogiri / httparty / colorize) or install via bundle 
   1º - make sure bundle is installed
      $ gem install bundle
      $ bundle install  --> inside the same dir when gemfile
- yara (only to use -y option)


```
                               ,##############*                                          
                         ####**/*******/*********/##.                                    
                       #******************************##                                 
                        ###/***************/************/##                              
                        ##(*#(*****//*********/************##                            
                        ../##*##//****/**********/**/********##                          
                       .#  ##.#/#(##****************/**********##                        
                            ##   ##**##/***********************/(#                       
                             #   #.* #***##/*/************/**/****#                      
                          #.,  ,##,   /./#***##(*******************#                     
                      ###/*(##.,.  #*%#. /,.# #***##/*******/*******#                    
                       #**/*##(***#,#  #.* ### ###/####/##*****#****#                    
                        #/*/*/***/###(*####..####.##,#.#######*/#***/#                   
                         #******/******/*(###############(****/#****/#                   
                          ##******************************#(*******/#                    
                            #(************//************************#                    
                              ##**********************/************#                     
                                 ##***/*//******************/*****#                      
                             ####    ###******************/*****(#          #*/*//#      
                  (******.   #****###     .######(//***********#/         #/*/##/***#    
                (/       (*# ##*****/(##          ##*********#/       ## (**#    #**/,   
               ./         #*# #/**/*//*/##      ##*******//#     ###***##//#      ***#   
                /#        #*( ##***#***/**#  ##/********###(*###******(#**#      .**/#   
                          (*#  #**/**##**(/#//*******(##**##(**//*(***#/##(   .##***/    
              #############/   /#//(###(*/#*******/##/*###/***/##*/**##/*********/*#     
              .#*****/*/**//*#####**/***#(********#..##**//*/*#/****## ###/***/*#(       
                #/****#(***/*/***/*###(/*#********###*/***//#*////###     #//**/##       
                 ##/*****###**#********##//******/#/****(*****//*****#         ##*(#     
                  ###/*****/((##*//**(****##****##****(///****/*/*****/#         (*#     
                #***###(//****//*(##*#(*/***/#*#//**#(*****/###***#**/*/##  #/   (*#     
               //*#    %%##*******#***********#/****/*****/#%%%%#*( *****.   *  .##,     
              /**#     %(((((((##*******///*/#/*/#%%%%%%(((((((%.(*##****#  ((           
 #(**#       #**/      %(((((((#**/**#(((((((((((((((((((((((((%  #/(/***#/**            
#*          #/*,       %(((((((***/#((((((((((((((((  (/(/(((/(*,,,,*////(,,((///////(*,,
*#         #**,        %(((((#****(((((((((((((((.,((( ((((/.((#,,,,*////((///((((((///(*
/(        /**            #%%(****((((((((((((((((((,(,(((######,,,,,,////(/(/,,,,,,,,(//(
/*(     #**#              %(#***##%%%%#((((((((#%%%%%%#(((((#%       #/**/           #/**
  #******#                %##***#(((((((((((((((((((((((((((%%       ##***/#        #**/#
                          %##**/((((((((((((((((((((((((((((%%      .#*#*****/*##(*****# 
               ####       %%#**/((((((((((((((((((((((((((((%%      *(/#  #***//**/*(%   
            (#/#####      (%#**/((((((((((((((((((((((((((((%*       #*#*                
           #*(             %#**/((((((((((((((((((((((((((((%         ##*                
           (*/             %#/**((((((((((((((((((((((((((((%                            
          (*/              %/**#(((((((((((((((((((((((((((#%                            
          .**/             #***((((((((((((((((((((((((((((%%                            
           #*#            #***(((((((((((((((((((((((((((((%%                            
            #**#         ***(((((((((((((((((((((((((((((((%,                            
             #/**/#* .#/***#%((((((((((((((((((((((((((((((%                             
                #/******#,  %((((((((((((((((((((((((((((((%                             
                            %((((((((((((((((((((((((((((((%                             
,.,.,.,,                    /%%%%#((((((((((((((((((((((#%%%              
 ```      

Special thanks to:

https://github.com/DiabloHorn/yara4pentesters

Awesome project =)
