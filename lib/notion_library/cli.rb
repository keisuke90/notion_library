require "notion_library"
require "thor"

module NotionLibrary
  class CLI < Thor
    desc "hello", "Prints 'Hello World!'"
    def hello
      puts "Hello World!"
    end
  end
end
