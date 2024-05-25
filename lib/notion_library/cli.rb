require "notion_library"
require "notion_library/notion/client"
require "notion_library/kindle/client"
require "thor"
require "dotenv"
require "uri"
require "net/http"
require "json"

module NotionLibrary
  class CLI < Thor
    desc "init_secret", "Initializes Secret Key"
    def init_secret
      Dotenv.load

      rakuten_app_id = ask_secret("RAKUTEN_APP_ID")
      notion_secret = ask_secret("NOTION_SECRET")
      notion_database_id = ask_secret("NOTION_DATABASE_ID")
      amazon_email = ask_secret("AMAZON_EMAIL")
      amazon_password = ask_secret("AMAZON_PASSWORD")

      File.open(File.join(__dir__, "../../.env"), "w") do |file|
        file.puts "RAKUTEN_APP_ID=#{rakuten_app_id}"
        file.puts "NOTION_SECRET=#{notion_secret}"
        file.puts "NOTION_DATABASE_ID=#{notion_database_id}"
        file.puts "AMAZON_EMAIL=#{amazon_email}"
        file.puts "AMAZON_PASSWORD=#{amazon_password}"
      end
    end

    desc "register", "Register a book"
    def register # rubocop:disable Metrics/AbcSize
      Dotenv.load
      notion_client = Notion::Client.new(ENV["NOTION_SECRET"], ENV["NOTION_DATABASE_ID"])

      keyword = ask("Please enter a keyword to search:")
      return if keyword.empty?

      book_search_result = search_books(keyword)
      books = JSON.parse(book_search_result.body)["Items"].map { |item| item["Item"] }
      selected_id = ask_target_book(books)

      puts "Registering the book..."
      result = notion_client.register_book(books[selected_id])
      if result.code == "200"
        puts "The book has been successfully registered."
      else
        puts "Failed to register the book. #{result.body}"
      end
    end

    desc "highlight", "Get highlights from Kindle"
    def highlight
      Dotenv.load
      kindle_client = Kindle::Client.new(ENV["AMAZON_EMAIL"], ENV["AMAZON_PASSWORD"])
      notion_client = Notion::Client.new(ENV["NOTION_SECRET"], ENV["NOTION_DATABASE_ID"])

      asin = ask("Please enter the ASIN of the book you want to get highlights from:")
      highlights = kindle_client.get_highlights(asin)
      result = notion_client.register_highlights(asin, highlights)
      binding.irb
      if result.code == "200"
        puts "The highlights have been successfully registered."
      else
        puts "Failed to register the highlights. #{result.body}"
      end
    end

    private

    def ask_secret(key)
      puts <<~RUBY
        Please enter your #{key}
        If you do not want to change it, leave it blank and press enter.
      RUBY
      res = ask("Please enter new #{key}:")
      res = ENV[key] if res.empty?
      res
    end

    def search_books(keyword)
      return unless keyword

      base_url = "https://app.rakuten.co.jp/services/api/BooksTotal/Search/20170404?applicationId="
      encoded_keyword = URI.encode_www_form_component(keyword)
      url = URI("#{base_url}#{ENV["RAKUTEN_APP_ID"]}&keyword=#{encoded_keyword}")
      Net::HTTP.get_response(url)
    end

    def ask_target_book(books)
      selected_id = nil
      while selected_id.nil?
        books.each_with_index do |book, idx|
          puts "[#{idx + 1}]#{book["title"]} / #{book["author"]} / #{book["publisherName"]}"
        end
        tmp_selected_id = ask("Please select a book by entering the number:")
        if tmp_selected_id.empty? || tmp_selected_id.to_i > books.size
          puts "Wrong input. Please enter the number of the book you want to register."
          return
        end
        puts "You selected: #{books[tmp_selected_id.to_i - 1]["title"]}"
        ask = ask("Do you want to register this book? (y/n)")
        selected_id = tmp_selected_id.to_i - 1 if %w[y yes].include?(ask.downcase)
      end
      selected_id
    end
  end
end

