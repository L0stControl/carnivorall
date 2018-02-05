    
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
        

Scan internal network looking for files with credentials and sensitive information.

Requirements:

- smbclient 
- xpdf-utils
- zip
- ruby
- yara (only to use -y option)
