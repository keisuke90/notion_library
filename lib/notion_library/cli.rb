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

      puts <<~RUBY
        Please enter your Rakuten App ID
        If you do not want to change it, leave it blank and press enter.
        Rakuten Web Service App ID: #{ENV["RAKUTEN_APP_ID"]}
      RUBY
      rakuten_app_id = ask("Please enter new Rakuten APP ID:")
      rakuten_app_id = ENV["RAKUTEN_APP_ID"] if rakuten_app_id.empty?

      File.open(File.join(__dir__, "../../.env"), "w") do |file|
        file.puts "RAKUTEN_APP_ID=#{rakuten_app_id}"
      end
    end

    desc "register", "Register a book"
    def register(keyword) # rubocop:disable all
      Dotenv.load
      base_url = "https://app.rakuten.co.jp/services/api/BooksTotal/Search/20170404?applicationId="
      keyword = URI.encode_www_form_component(keyword)
      url = URI("#{base_url}#{ENV["RAKUTEN_APP_ID"]}&keyword=#{keyword}")
      res = Net::HTTP.get_response(url)

      books = JSON.parse(res.body)["Items"].map { |item| item["Item"] }
      books.each_with_index do |book, idx|
        puts "[#{idx + 1}]---------------"
        puts "Title: #{book["title"]}"
        puts "Author: #{book["author"]}"
        puts "Publisher: #{book["publisherName"]}"
        puts "ISBN: #{book["isbn"]}"
        puts "URL: #{book["largeImageUrl"]}"
      end

      selected_id = ask("Please select a book by entering the number:")
      return if selected_id.empty?

      puts "You selected: #{books[selected_id.to_i - 1]["title"]}"

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
            "url": books[selected_id.to_i - 1]["largeImageUrl"]
          }
        },
        "properties" => {
          "Title": {
            "title": [
              {
                "text": {
                  "content": books[selected_id.to_i - 1]["title"]
                }
              }
            ]
          },
          "Author": {
            "rich_text": [
              {
                "type": "text",
                "text": {
                  "content": books[selected_id.to_i - 1]["author"]
                }
              }
            ]
          },
          "Publisher": {
            "rich_text": [
              {
                "type": "text",
                "text": {
                  "content": books[selected_id.to_i - 1]["publisherName"]
                }
              }
            ]
          },
          "ISBN": {
            "number": books[selected_id.to_i - 1]["isbn"].to_i
          }
        }
      }.to_json
      begin
        response = Net::HTTP.post(notion_endpoint, body, headers)
      rescue StandardError => e
        puts e
      end
      puts response.body
    end
  end
end
