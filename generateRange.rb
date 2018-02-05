#!/usr/bin/env ruby

require 'ipaddr'

if ARGV.empty?
	puts
	print "Type: ./generateRange.rb 192.168.0.0/24\n"
else
	puts IPAddr.new(ARGV[0]).to_range.to_a
end
