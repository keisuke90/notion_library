module Notion
  class Client
    def initialize
      Dotenv.load
      @notion_secret = ENV["NOTION_SECRET"]
      @notion_database_id = ENV["NOTION_DATABASE_ID"]
    end

    def register_book(book)
      notion_endpoint = URI.parse("https://api.notion.com/v1/pages")
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

    def register_highlights(asin, highlights)
      notion_endpoint = URI.parse("https://api.notion.com/v1/databases/#{@notion_database_id}/query")
      body = {
        "filter": {
          "property": "ASIN",
          "rich_text": {
            "equals": asin
          }
        }
      }.to_json
      response = Net::HTTP.post(notion_endpoint, body, headers)
      page_id = JSON.parse(response.body)["results"][0]["id"]
    end

    private

    def headers
      {
        "Authorization" => "Bearer #{@notion_secret}",
        "Content-Type" => "application/json",
        "Notion-Version" => "2022-06-28"
      }
    end
  end
end
