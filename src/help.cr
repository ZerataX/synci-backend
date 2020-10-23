require "option_parser"
require "./websocket"

OptionParser.parse do |parser|
  parser.banner = "synci signaling server"

  parser.on "-v", "--version", "Show version" do
    puts "version #{{{`shards version #{__DIR__}`.stringify}}}"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
  parser.on "-s", "--start", "Start server" do
    puts "run server"
    # Kemal.run(3030)
    exit
  end
  parser.missing_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is missing something."
    STDERR.puts ""
    STDERR.puts parser
    exit(1)
  end
  parser.invalid_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end