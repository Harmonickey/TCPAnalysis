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
    `sudo cp #{pcap} thrpt/pcap/`
    xpl_dir = "thrpt/xpl_#{Time.now.to_i.to_s}"
    `mkdir #{xpl_dir}`

    gpl_dir = "thrpt/gpl_#{Time.now.to_i.to_s}"

    tcptrace xpl_dir, "thrpt/pcap/#{pcap}"
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
    output = `sudo tcptrace -l --output_dir="#{dir}" #{pcap}`

    parseOutput output
  end

  def self.parseOutput output
    File.open("thrpt/test_output_there.dataset", "w") do |dt_file|
    File.open("thrpt/test_output_back.dataset", "w") do |db_file|
      tcp_connections = output.split("================================")
      is_first_conn = true
      first_time = 0
      time_stamp = 0
      offset = 7
      minoffset = 0
      tcp_connections.each do |conn|
        data = conn.split("\n")
        throughputThere = parseThroughput data[data.length - 1], 'there'
        next if throughputThere == 'NA'
        throughputBack = parseThroughput data[data.length - 1], 'back'
        minoffset = parseTimestampMin data[5 + offset], time_stamp, minoffset
        time_stamp = parseTimestamp data[5 + offset]
        if is_first_conn
          offset = 0
          is_first_conn = false
          first_time = time_stamp
        end
        dt_file.puts (time_stamp + (minoffset * 60) - first_time).to_s + " " + throughputThere.to_s
        db_file.puts (time_stamp + (minoffset * 60) - first_time).to_s + " " + throughputBack.to_s
      end
    end
    end
    File.open("thrpt/test_output.gpl", "w") do |g_file|
      g_file.puts "set   autoscale                        # scale axes automatically"
      g_file.puts "unset log                              # remove any log-scaling"
      g_file.puts "unset label                            # remove any previous labels"
      g_file.puts "set xtic auto                          # set xtics automatically"
      g_file.puts "set ytic auto                          # set ytics automatically"
      g_file.puts "set title 'Throughput vs Time'"
      g_file.puts "set xlabel 'Timestamp (minute)'"
      g_file.puts "set ylabel 'Throughput (Bps)'"
      g_file.puts "plot    'test_output_there.dataset' using 1:2 title 'There' with linespoints , \\"
      g_file.puts "        'test_output_back.dataset' using 1:2 title 'Back' with linespoints" 
    end
    File.open("thrpt/test_output2.gpl", "w") do |g_file|
      g_file.puts "set   autoscale                        # scale axes automatically"
      g_file.puts "unset log                              # remove any log-scaling"
      g_file.puts "unset label                            # remove any previous labels"
      g_file.puts "set xtic auto                          # set xtics automatically"
      g_file.puts "set ytic auto                          # set ytics automatically"
      g_file.puts "set title 'Throughput vs Time'"
      g_file.puts "set xlabel 'Timestamp (minute)'"
      g_file.puts "set ylabel 'Throughput (Bps)'"
      g_file.puts "set yrange [1:5000]"
      g_file.puts "plot    'test_output_there.dataset' using 1:2 title 'There' with linespoints , \\"
      g_file.puts "        'test_output_back.dataset' using 1:2 title 'Back' with linespoints" 
    end
  end

  def self.parseThroughput tp, which
    parts = tp.split(" ")
    offset = 1 if which == 'there'
    offset = 4 if which == 'back' 
    parts[offset]
  end

  def self.parseTimestamp ts
    parts = ts.split(" ")
    time = Time.parse(parts[5].to_s)
    time.sec
  end

  def self.parseTimestampMin ts, prev, minoffset
    parts = ts.split(" ")
    time = Time.parse(parts[5].to_s)
    (prev > time.sec ? minoffset + 1 : minoffset)
  end
end

TCPAnalysis.analyzePcap 'out2.pcap'
