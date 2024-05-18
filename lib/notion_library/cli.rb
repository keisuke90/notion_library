require "notion_library"
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

      File.open(File.join(__dir__, "../../.env"), "w") do |file|
        file.puts "RAKUTEN_APP_ID=#{rakuten_app_id}"
        file.puts "NOTION_SECRET=#{notion_secret}"
        file.puts "NOTION_DATABASE_ID=#{notion_database_id}"
      end
    end

    desc "register", "Register a book"
    def register # rubocop:disable Metrics/AbcSize
      Dotenv.load

      # 本の検索
      keyword = ask("Please enter a keyword to search:")
      return if keyword.empty?

      book_search_result = search_books(keyword)

      # Notionに登録したい本の選択
      selected_id = nil
      while selected_id.nil?
        books = JSON.parse(book_search_result.body)["Items"].map { |item| item["Item"] }
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

      # Notion APIを使って本を登録する
      puts "Registering the book..."
      registration_result = register_book(books[selected_id])
      if registration_result.code == "200"
        puts "The book has been successfully registered."
      else
        puts "Failed to register the book."
      end
    end

    desc "kindle", "Kindle"
    def kindle
      client = Kindle::Client.new
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

    def register_book(book)
      notion_endpoint = URI("https://api.notion.com/v1/pages")
      notion_secret = ENV["NOTION_SECRET"]
      notion_database_id = ENV["NOTION_DATABASE_ID"]
      headers = {
        "Authorization" => "Bearer #{notion_secret}",
        "Content-Type" => "application/json",
        "Notion-Version" => "2022-06-28"
      }
      body = {
        "parent" => { "database_id" => notion_database_id },
        "cover" => {
          "external" => {
            "url": book["largeImageUrl"]
          }
        },
        "properties" => {
          "Title": {
            "title": [
              {
                "text": {
                  "content": book["title"]
                }
              }
            ]
          },
          "Author": {
            "rich_text": [
              {
                "type": "text",
                "text": {
                  "content": book["author"]
                }
              }
            ]
          },
          "Publisher": {
            "rich_text": [
              {
                "type": "text",
                "text": {
                  "content": book["publisherName"]
                }
              }
            ]
          },
          "ISBN": {
            "number": book["isbn"].to_i
          }
        }
      }.to_json
      begin
        response = Net::HTTP.post(notion_endpoint, body, headers)
      rescue StandardError => e
        puts e
      end
      response
    end
  end
end
