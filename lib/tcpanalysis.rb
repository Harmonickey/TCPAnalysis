
class TCPAnalysis

  def self.info
    puts "This is a TCP Analysis Tool made by Northwestern!"
  end

  def self.run lanPort
    if lanPort.nil?
      puts "Need a LAN Port to listen on!"
      puts "Example: wlan0"
    end

    puts "What do you want to capture? : Ex. G"
    @tcptraceOpts = gets.chomp

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

    `sudo mv #{pcap} tmp/pcap/`

    @xpl_dir = "tmp/xpl_#{Time.now.to_i.to_s}"

    `mkdir #{@xpl_dir}`
    #run tcptrace on the return pcap file
    tcptrace @tcptraceOpts, @xpl_dir, "tmp/pcap/#{pcap}"

    @gpl_dir = "tmp/gpl_#{Time.now.to_i.to_s}"

    `mkdir #{@gpl_dir}`

    #get the gpl file
    getGpl @xpl_dir, @gpl_dir

    #gnuplot
    gnuplot @gpl_dir
  end

  def self.tcpdump interface, input, type
    if type == 'T'
      `sudo tcpdump -i #{interface} -G #{input} -z rerun_with_pcap.rb -w out.pcap`
    elsif type == 'N'
      `sudo tcpdump -i #{interface} -c #{input} -w out.pcap`
    end
    analyzePcap "out.pcap"
  end
  
  def self.tcptrace options, dir, pcap 
    `sudo tcptrace -#{options} --output_dir="#{dir}" #{pcap}`
  end

  def self.getGpl xpl, gpl
    @xpl_files = `find #{xpl} -type f -print | grep .xpl`.split("\n").map{ |file| file.gsub('./', '')}
    @xpl_files.each do |file|
      `sudo xpl2gpl #{file}`
    end 
  end

  def self.gnuplot gpl

    move_files gpl, ".gpl"
    move_files gpl, ".datasets"
    move_files gpl, ".labels"

    sort_into_own_dir gpl, "rtt"
    sort_into_own_dir gpl, "tput"
    sort_into_own_dir gpl, "ssize"
    sort_into_own_dir gpl, "owin"
    sort_into_own_dir gpl, "tsg"
    sort_into_own_dir gpl, "tline"

    #`gnuplot #{@gpl_files}`
  end
 
  def self.move_files gpl, pattern
    @matched_files = `find . -type f -print | grep #{pattern}`.split("\n").map{ |file| file.gsub('./', '')}.sort().join(" ").split(" ")
    @matched_files.each do |file|
      `sudo mv #{file} #{gpl}`
    end
  end

  def self.sort_into_own_dir dir, pattern
    @matched_files = `find #{dir} -type f -print | grep #{pattern}`.split("\n").map{ |file| file.gsub('./', '')}.sort().join(" ").split(" ")
    `mkdir #{dir}/#{pattern}`
    @matched_files.each do |file|
      `sudo mv #{file} #{dir}/#{pattern}`
    end
  end
end

