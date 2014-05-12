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

    #puts "What do you want to capture? : Ex. G"
    #@tcptraceOpts = gets.chomp

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

  def self.analyzePcap2 pcap
    `sudo mv #{pcap} tmp/pcap/`
    xpl_dir = "tmp/xpl_#{Time.now.to_i.to_s}"
    `mkdir #{xpl_dir}`

    gpl_dir = "tmp/gpl_#{Time.now.to_i.to_s}"

    tcptrace2 xpl_dir, "tmp/pcap/#{pcap}"
  end

  def self.analyzePcap pcap
    if @tcptraceOpts.nil?
      puts "What do you want to capture? Ex. G"
      @tcptraceOpts = gets.chomp
    end

    puts "Moving pcap file"
    `sudo mv #{pcap} tmp/pcap/`
    puts "Finished moving pcap file"

    parts = pcap.split("/")
    @pcap_file = parts[parts.size]

    @xpl_dir = "tmp/xpl_#{Time.now.to_i.to_s}"

    `mkdir #{@xpl_dir}`
    #run tcptrace on the return pcap file
    puts "#{@tcptraceOpts} #{@xpl_dir} tmp/pcap/#{pcap}"
    tcptrace @tcptraceOpts, @xpl_dir, "tmp/pcap/#{pcap}"

    @gpl_dir = "tmp/gpl_#{Time.now.to_i.to_s}"

    `mkdir #{@gpl_dir}`

    #get the gpl file
    getGpl @xpl_dir, @gpl_dir

    #gnuplot
    gnuplot @gpl_dir
  end

  def self.tcpdump interface, input, type
    puts "Starting TCPDump"
    if type == 'T'
      `sudo tcpdump -i #{interface} -w out2.pcap & sleep #{input}s && sudo pkill -HUP -f tcpdump` 
    elsif type == 'N'
      `sudo tcpdump -i #{interface} -c #{input} -w out2.pcap`
    end
    puts "Finished TCPDump"
    analyzePcap2 "out2.pcap"
  end
  
  def self.tcptrace options, dir, pcap 
    puts "Starting TCPTrace"
    puts "sudo tcptrace -#{options} --output_dir=#{dir} #{pcap}"
    `sudo tcptrace -#{options} --output_dir="#{dir}" #{pcap}`
    puts "Finishing TCPTrace"
  end

  def self.tcptrace2 dir, pcap
    output = `sudo tcptrace -l --output_dir="#{dir}" #{pcap}`

    parseOutput output
  end

  def self.tcptrace3 dir, pcap
    output = `sudo tcptrace -rl --output_dir="#{dir}" #{pcap}`

    parseOutput2 output
  end

  def self.parseOutput2 output
    File.open("test_output_there.dataset", "w") do |dt_file|
    File.open("test_output_back.dataset", "w") do |db_file|
      tcp_connections = output.split("================================")
      tcp_connections.each do |conn|
        data = conn.split("\n")
        rttThere = parseRTT data[data.length - 20], 'there'
        next if rttThere == 'NA'
        rttBack = parseRTT data[data.length - 20], 'back'
        connection = parseConnection data[0]
        dt_file.puts connection.to_s + " " + rttThere.to_s
        db_file.puts connection.to_s + " " + rttBack.to_s
      end
    end
    end
    File.open("test_output.gpl", "w") do |g_file|
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
  end

  def self.parseRTT rtt, which
    parts = rtt.split(" ")
    offset = 2 if which == 'there'
    offset = 6 if which == 'back' 
    parts[offset]
  end

  def self.parseConnection conn
    parts = conn.split(" ")
    parts[2].split(":")[0]
  end

  def self.parseOutput output
    File.open("test_output_there.dataset", "w") do |dt_file|
    File.open("test_output_back.dataset", "w") do |db_file|
      tcp_connections = output.split("================================")
      is_first_conn = true
      offset = 7
      tcp_connections.each do |conn|
        data = conn.split("\n")
        throughputThere = parseThroughput data[data.length - 1], 'there'
        next if throughputThere == 'NA'
        throughputBack = parseThroughput data[data.length - 1], 'back'
        time_stamp = parseTimestamp data[5 + offset]
        dt_file.puts time_stamp.to_s + " " + throughputThere.to_s
        db_file.puts time_stamp.to_s + " " + throughputBack.to_s
        if is_first_conn
          offset = 0
          is_first_conn = false
        end
      end
    end
    end
    File.open("test_output.gpl", "w") do |g_file|
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
    time.to_i
  end

  def self.getGpl xpl, gpl
    @xpl_files = `find #{xpl} -type f -print | grep .xpl`.split("\n").map{ |file| file.gsub('./', '')}
    puts "Converting all xpl to gpl"
    @xpl_files.each do |file|
      `sudo xpl2gpl #{file}`
    end 
    puts "Finished conversion"
  end

  def self.gnuplot gpl

    puts "Moving and sorting all relavant files"
    move_files gpl, ".gpl"
    move_files gpl, ".datasets"
    move_files gpl, ".labels"

    gpl_dirs = Array.new

    gpl_dirs.push sort_into_own_dir gpl, "rtt"
    gpl_dirs.push sort_into_own_dir gpl, "tput"
    gpl_dirs.push sort_into_own_dir gpl, "ssize"
    gpl_dirs.push sort_into_own_dir gpl, "owin"
    gpl_dirs.push sort_into_own_dir gpl, "tsg"
    gpl_dirs.push sort_into_own_dir gpl, "tline"
    puts "Finished move and sort"

    puts "Starting plots"
    gpl_dirs.each do |dir|
      Dir.chdir "#{dir}" do 
        puts "Directory #{dir}"
        gpl_files = `find . -type f -print | grep .gpl`.split("\n").map{ |file| file.gsub('./', '')}.sort().join(" ")
        puts "gnuplot #{gpl_files}"
        spawn "gnuplot -p #{gpl_files}"
      end
    end
    puts "Finished plots"
  end
 
  def self.move_files gpl, pattern
    matched_files = `find . -type f -print | grep #{pattern}`.split("\n").map{ |file| file.gsub('./', '')}.sort().join(" ").split(" ")
    matched_files.each do |file|
      `sudo mv #{file} #{gpl}`
    end
  end

  def self.sort_into_own_dir dir, pattern
    matched_files = `find #{dir} -type f -print | grep #{pattern}`.split("\n").map{ |file| file.gsub('./', '')}.sort().join(" ").split(" ")
    `mkdir #{dir}/#{pattern}`
    matched_files.each do |file|
      `sudo mv #{file} #{dir}/#{pattern}`
    end
    return "#{dir}/#{pattern}"
  end
end

