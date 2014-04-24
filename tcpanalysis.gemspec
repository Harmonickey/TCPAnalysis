Gem::Specification.new do |s|
  s.name           = 'tcpanalysis'
  s.version        = '0.0.0'
  s.date           = '2014-04-16'
  s.summary        = 'Performs TCP Analysis'
  s.description    = 'A comprehensive TCP Analysis tool to monitor cellular versus wifi TCP communication'
  s.authors        = ["Alex Ayerdi", "Mas-ud Hussain", "Kamalakar Kambhatla"]
  s.email          = 'AAyerdi@u.northwestern.edu'
  s.files          = `git ls-files`.split($\)
  s.bindir         = 'bin'
  s.homepage       = 'https://github.com/Harmonickey/TCPAnalysis'
  s.license        = 'MIT'
  s.require_paths  = ["lib", "tmp"]
  s.executables    = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
end
