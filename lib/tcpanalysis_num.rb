require 'time'

class TCPAnalysis

  def self.info
    puts "This is a TCP Analysis Tool made by Northwestern!"
  end

  def self.run lanPort
    if lanPort.nil?
      puts "Need a LAN Port to listen on!"
      puts "Example: wlan0"
    end

    begin 
      puts "Do you want to do 'Time Capture' or 'Num Packets Capture : T or N'"
      @type = gets.chomp
    end while @type != 'T' and @type != 'N'
     
    #run tcpdump
    if @type == 'T'
      puts "How much time do you want to run to capture? : #"
      @time_capture = gets.chomp
      tcpdump lanPort, @time_capture, @type
    elsif @type == 'N'
      puts "How many packets do you want to capture? : #"
      @num_packets = gets.chomp
      tcpdump lanPort, @num_packets, @type
    end
  
  end

  def self.analyzePcap pcap
    `sudo cp #{pcap} num/pcap/`
    xpl_dir = "num/xpl_#{Time.now.to_i.to_s}"
    `mkdir #{xpl_dir}`

    gpl_dir = "num/gpl_#{Time.now.to_i.to_s}"

    tcptrace xpl_dir, "num/pcap/#{pcap}"
  end

  def self.tcpdump interface, input, type
    puts "Starting TCPDump"
    if type == 'T'
      `sudo tcpdump -i #{interface} -w out.pcap & sleep #{input}s && sudo pkill -HUP -f tcpdump` 
    elsif type == 'N'
      `sudo tcpdump -i #{interface} -c #{input} -w out.pcap`
    end
    puts "Finished TCPDump"
    analyzePcap "out.pcap"
  end
  
  def self.tcptrace dir, pcap
    output = `sudo tcptrace -lrW --output_dir="#{dir}" #{pcap}`
    File.open("num/tcptrace.txt", "w") do |tt_file|
    	tt_file.puts output
    end
    parseOutput output
  end

  def self.parseOutput output
      @max_packets = 0
      @conn = 0
      @rttThere = 0
      @rttBack = 0
      @rpThere = 0
      @rpBack = 0
      @oopBack = 0
      @oopThere = 0
      @thrptThere = 0
      @thrptBack = 0
      tcp_connections = output.split("================================")
      tcp_connections.each do |conn|
        data = conn.split("\n")
        numpackets = parseNumPackets data[8] 
        if numpackets == '1:'
          numpackets = parseNumPackets data[15]
        end
        if @max_packets.to_i < numpackets.to_i
          @max_packets = numpackets
          @conn = parseConnection data, 'connection'
          @rttThere = parseRTT data, 'RTT avg:', 'there'
          @rttBack = parseRTT data, 'RTT avg:', 'back'
          @rpThere = parseRxmt data, 'rexmt data pkts:', 'there'
          @rpBack = parseRxmt data, 'rexmt data pkts:', 'back'
          @oopThere = parseOOP data, 'outoforder pkts:', 'there'
          @oopBack = parseOOP data, 'outoforder pkts:', 'back'
          @thrptThere = parseThrpt data, 'throughput:', 'there'
          @thrptBack = parseThrpt data, 'throughput:', 'back'
        end
      end
      puts "What is this for?"
      name = gets.chomp
      File.open("num/data/#{name}", "w+") do |aFile|
        aFile.puts "Your Connection: #{@conn} Had #{@max_packets} packets!"
        aFile.puts "Round trip time 'there' was #{@rttThere}"
        aFile.puts "Round trip time 'back' was #{@rttBack}"
        aFile.puts "Retransmitted packets 'there' was #{@rpThere}"
        aFile.puts "Retransmitted packets 'back' was #{@rpBack}"
        aFile.puts "Out of order packets sending 'there' was #{@oopThere}"
        aFile.puts "Out of order packets receiving 'back' was #{@oopBack}"
        aFile.puts "Throughput 'there' was #{@thrptThere}"
        aFile.puts "Throughput 'back' was #{@thrptBack}"
        aFile.puts "Estimated Packet Loss Rate 'there' was #{@rpThere.to_i / @max_packets.to_i}"
        aFile.puts "Estimated Packet Loss Rate 'back' was #{@rpBack.to_i / @max_packets.to_i}"
      end
  end

  def self.parseNumPackets packetline
    parts = packetline.split(" ")
    parts[2]
  end

  def self.findEntry data, pattern
    @foundLine = nil
    data.each do |line|
      if line.index pattern
        @foundLine = line
      end
    end
    @foundLine
  end

  def self.parseConnection data, conn
    line = findEntry data, conn
    parts = line.split(" ")
    otherParts = parts[2].split(":")
    otherParts[0] = 0 if otherParts[0] == '--'
    otherParts[0]
  end

  def self.parseRTT data, rtt, which
    line = findEntry data, rtt
    parts = line.split(" ")
    offset = 2 if which == 'there'
    offset = 6 if which == 'back' 
    parts[offset]
  end

  def self.parseRxmt data, rxmt, which
    line = findEntry data, rxmt
    parts = line.split(" ")
    offset = 3 if which == 'there'
    offset = 7 if which == 'back' 
    parts[offset]
  end

  def self.parseOOP data, oop, which
    line = findEntry data, oop
    parts = line.split(" ")
    offset = 2 if which == 'there'
    offset = 5 if which == 'back' 
    parts[offset]
  end
 
  def self.parseThrpt data, thrpt, which
    line = findEntry data, thrpt
    parts = line.split(" ")
    offset = 1 if which == 'there'
    offset = 4 if which == 'back'
    parts[offset]
  end
end

TCPAnalysis.analyzePcap 'out2.pcap'
