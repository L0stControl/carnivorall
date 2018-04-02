#!/usr/bin/env ruby
#=========================================================================
#Title           :scraping.rb
#Description     :Get files from the internet using search engines
#Authors         :L0stControl
#Date            :2018/04/02
#Version         :0.1.1    
#Dependecies     :nokogiri / HTTParty / colorize
#=========================================================================

require 'nokogiri'
require 'httparty'
require 'colorize'

tmpDir=ARGV[2]
listLinks = []
qtSearch = 0
startItems = 0

if ARGV[1].to_i > 100 

    if ARGV[1] % 100 != 0
        qtSearch = ( ARGV[1].to_i / 100 ) + 1 
      else
        qtSearch = ARGV[1].to_i / 100 
    end	

else

	 qtSearch = 1

end

if ARGV[1].to_i < 100
    items = ARGV[1]
else
    items = 100
end

# Using google to search files 

def getListFiles(domain, startItems, qtItems)
    if qtItems == "0"
            puts
            puts  " [+]".green + " Looking for suspicious content in local files ".white
    else
        begin #proxy , http_proxyaddr:"115.70.28.209", http_proxyport:"53281"}
            HTTParty.get("https://www.google.com.br/search?q=site:#{domain}+(+filetype:xlsx+%7C+filetype:xls+%7C+filetype:docx+%7C+filetype:doc+%7C+filetype:pptx+%7C+filetype:ppt+%7C+filetype:txt+%7C+ext:conf+%7C+filetype:csv+%7C+filetype:cnf+%7C+filetype:xml+%7C+filetype:pdf+%7C+ext:key+%7C+ext:ovpn+%7C+ext:log+%7C+filetype:pcf+)&num=#{qtItems}&start=#{(startItems * 100) + 1}&sa=N&filter=0")
        rescue Exception => e
            puts "Error trying to use Google, please check your internet connection!"
            puts "\nDEBUG: #{e.message}\n"
        end
    end
end

if ARGV[1] != "0"
    puts  "\n [+]".green + " Looking for suspicious content using Google dorks \n".white
end

(qtSearch.to_i).times do |qt|

    htmlDoc = Nokogiri::HTML(getListFiles(ARGV[0], qt, items))
    linksRaw = htmlDoc.css("h3.r").css("a")
    linksRaw.each_entry do |line|
   
        listLinks.push(line.to_s)

    end
end

if listLinks.length != 0

# Download files
    listLinks.each do |linkRaw|
    
        link = URI.decode(linkRaw.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8').split("=")[2].split("&")[0] )
        fileName = link.split("/").last
        print " [+]".green + " Downloading File: #{link}.... ".white

        begin
        remoteFile = HTTParty.get(link, {headers: {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Carnivorall/0.6.1 Safari/537.36"}})
        puts "[OK]".green
            File.open("#{tmpDir}/#{fileName}", "w") do |file|
                file.write(remoteFile)   
                file.close
             # Exiftool
            end
        
        rescue
            puts "[FAIL]".red
    
        end
    end
end

puts ""
