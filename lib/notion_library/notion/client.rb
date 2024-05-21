module Notion
  class Client
    def initialize
      Dotenv.load
      @url = "https://api.notion.com/v1/pages"
      @notion_secret = ENV["NOTION_SECRET"]
      @notion_database_id = ENV["NOTION_DATABASE_ID"]
    end

    def register_book(book)
      notion_endpoint = URI.parse(@url)
      headers = {
        "Authorization" => "Bearer #{@notion_secret}",
        "Content-Type" => "application/json",
        "Notion-Version" => "2022-06-28"
      }
      body = {
        "parent" => { "database_id" => @notion_database_id },
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