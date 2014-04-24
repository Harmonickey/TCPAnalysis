#require 'pcaprub

class TCPAnalysis

  def self.info
    puts "This is a TCP Analysis Tool made by Northwestern!"
  end

  def self.run lanPort
    if lanPort.nil?
      puts "Need a LAN Port to listen on!"
      puts "Example: wlan0"
    end

    puts "What do you want to capture?"
    @tcptraceOpts = gets.chomp

    puts "How many packets do you want to capture?"
    @num_packets = gets.chomp

    #run tcpdump
    tcpdump lanPort, @num_packets

    @xpl_dir = "tmp/xpl_#{Time.now.to_i.to_s}/"

    `mkdir #{@xpl_dir}`
    #run tcptrace on the return pcap file
    tcptrace @tcptraceOpts, @xpl_dir

    @gpl_dir = "tmp/gpl_#{Time.now.to_i.to_s}/"

    `mkdir #{@gpl_dir}`

    #get the gpl file
    getGpl @xpl_dir, @gpl_dir

    #gnuplot
    gnuplot
  end

  def self.tcpdump interface, num_packets 
    `sudo tcpdump -i #{interface} -c #{num_packets} -w tmp/pcap/out.pcap`
  end
  
  def self.tcptrace options, dir 
    `sudo tcptrace -#{options} tmp/pcap/out.pcap --output_dir="#{dir}"`
  end

  def self.getGpl xpl, gpl
    @xpl_files = `find #{xpl} -type f -print | grep .xpl`.split("\n").map{ |file| file.gsub('./', '')}
    @xpl_files.each do |file|
      `sudo xpl2gpl #{file} > #{gpl}`
    end 
  end

  def self.gnuplot
    @gpl_files = `find . -type f -print | grep .gpl`.split("\n").map{ |file| file.gsub('./', '')}.sort().join(" ")
    `gnuplot #{@gpl_files}`
  end
end

