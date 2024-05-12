require "notion_library"
require "thor"
require "dotenv"
require "uri"
require "net/http"
require "json"

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

    desc "register", "Register a book"
    def register(keyword)
      Dotenv.load
      base_url = "https://app.rakuten.co.jp/services/api/BooksTotal/Search/20170404?applicationId="
      keyword = URI.encode_www_form_component(keyword)
      url = URI("#{base_url}#{ENV["RAKUTEN_APP_ID"]}&keyword=#{keyword}")
      res = Net::HTTP.get_response(url)
      
      books = JSON.parse(res.body)["Items"].map { |item| item["Item"] }
      books.each_with_index do |book, idx|
        puts "[#{idx+1}]---------------"
        puts "Title: #{book["title"]}"
        puts "Author: #{book["author"]}"
        puts "Publisher: #{book["publisherName"]}"
        puts "ISBN: #{book["isbn"]}"
        puts "URL: #{book["largeImageUrl"]}"
      end

      selected_id = ask("Please select a book by entering the number:")
      return if selected_id.empty?
      puts "You selected: #{books[selected_id.to_i-1]["title"]}"
    end
  end
end
