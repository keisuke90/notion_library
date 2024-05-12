require "notion_library"
require "thor"
require "dotenv"

module NotionLibrary
  class CLI < Thor
    desc "hello", "Prints 'Hello World!'"
    def hello
      puts "Hello World!"
    end

    desc "init", "Initializes Secret Key"
    def init_notion_library
      Dotenv.load
      puts "Please enter your Rakuten App ID\nIf you do not want to change it, leave it blank and press enter.\nRakuten Web Service App ID: #{ENV["RAKUTEN_APP_ID"]}"
      rakuten_app_id = ask("Please enter new Rakuten APP ID:")
      rakuten_app_id = ENV["RAKUTEN_APP_ID"] if rakuten_app_id.empty?

      File.open(File.join(__dir__, "../../.env"), "w") do |file|
        file.puts "RAKUTEN_APP_ID=#{rakuten_app_id}"
      end
    end
  end
end
