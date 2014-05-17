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
    `sudo mv #{pcap} rtt/pcap/`
    xpl_dir = "rtt/xpl_#{Time.now.to_i.to_s}"
    `mkdir #{xpl_dir}`

    gpl_dir = "rtt/gpl_#{Time.now.to_i.to_s}"

    tcptrace xpl_dir, "rtt/pcap/#{pcap}"
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
    output = `sudo tcptrace -rl --output_dir="#{dir}" #{pcap}`
    File.open("rtt/tcptrace.txt", "w") do |tt_file|
    	tt_file.puts output
    end
    parseOutput output
  end

  def self.parseOutput output
    File.open("rtt/test_output_there.dataset", "w") do |dt_file|
    File.open("rtt/test_output_back.dataset", "w") do |db_file|
      tcp_connections = output.split("================================")
      tcp_connections.each do |conn|
        data = conn.split("\n")
        rttThere = parseRTT data[data.length - 20], 'there'
        next if rttThere == 'NA'
        rttBack = parseRTT data[data.length - 20], 'back'
        connection = parseConnection data[1]
        if rttThere == 'stdev:'
	   rttThere = parseRTT data[data.length - 29], 'there'
           rttBack = parseRTT data[data.length - 29], 'back'
        end
        if connection == '--'
           connection = parseConnection data[8]
        end  
        dt_file.puts connection.to_s + " " + rttThere.to_s
        db_file.puts connection.to_s + " " + rttBack.to_s
      end
    end
    end
    File.open("rtt/test_output.gpl", "w") do |g_file|
      g_file.puts "set   autoscale                        # scale axes automatically"
      g_file.puts "unset log                              # remove any log-scaling"
      g_file.puts "unset label                            # remove any previous labels"
      g_file.puts "set xtic auto                          # set xtics automatically"
      g_file.puts "set ytic auto                          # set ytics automatically"
      g_file.puts "set title 'Throughput vs Time'"
      g_file.puts "set xlabel 'Connection (ID)'"
      g_file.puts "set ylabel 'RTT (ms)'"
      g_file.puts "plot    'test_output_there.dataset' using 1:2 title 'There' with linespoints , \\"
      g_file.puts "        'test_output_back.dataset' using 1:2 title 'Back' with linespoints" 
    end
  end

  def self.parseRTT rtt, which
    parts = rtt.split(" ")
    offset = 2 if which == 'there'
    offset = 6 if which == 'back' 
    parts[offset]
  end

  def self.parseConnection conn
    parts = conn.split(" ")
    otherParts=parts[2].split(":")
    otherParts[0]
  end
end

TCPAnalysis.analyzePcap 'out2.pcap'
