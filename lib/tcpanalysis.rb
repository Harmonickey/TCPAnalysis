class TCPAnalysis

  def self.info
    puts "This is a TCP Analysis Tool made by Northwestern!"
  end

  def self.tcpdump options
    `tcpdump #{options}`
  end

end
