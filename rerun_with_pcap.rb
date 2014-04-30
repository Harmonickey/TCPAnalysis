#!/usr/bin/ruby

require 'tcpanalysis'

@processes = `ps -ef | grep tcpdump`.split("\n")

@processes.each do |proc|
  @pid = proc.split()[1]
  `sudo kill #{@pid}`
end

TCPAnalysis.analyzePcap 'out.pcap' 
